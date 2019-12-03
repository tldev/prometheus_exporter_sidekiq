# frozen_string_literal: true

# collects stats from currently running process
module PrometheusExporterSidekiq
  class Instrumentation
    SIDEKIQ_STATS = %i[failed processed retry_size dead_size scheduled_size workers_size].freeze

    def self.start(client: nil, frequency: 10) }
      process_collector = new
      client ||= PrometheusExporter::Client.default

      stop if @thread

      @thread = Thread.new do
        while true
          begin
            metric = process_collector.collect
            client.send_json(metric)
          rescue => e
            STDERR.puts("Prometheus Exporter Failed To Collect Sidekiq Global Stats #{e}")
          ensure
            sleep frequency
          end
        end
      end
    end

    def self.stop
      if t = @thread
        t.kill
        @thread = nil
      end
    end

    def initialize(metric_labels: {}, sidekiq_stats: Sidekiq::Stats, sidekiq_queue: Sidekiq::Queue, senate: nil)
      @senate = senate || determine_senate
      @sidekiq_stats = sidekiq_stats
      @sidekiq_queue = sidekiq_queue

      @metric_labels = metric_labels
    end

    def collect
      metric = {}
      metric[:type] = PrometheusExporterSidekiq.type
      metric[:metric_labels] = @metric_labels
      collect_sidekiq_stats(metric)
      metric
    end

    def collect_sidekiq_stats(metric)
      current_stats = @sidekiq_stats.new
      SIDEKIQ_STATS.each do |stat|
        metric["sidekiq_#{stat}"] = current_stats.send(stat)
      end

      metric[:sidekiq_enqueued] = @sidekiq_queue.sum { |queue| queue.size }
    end

    private

    def determine_senate
      if Object.const_defined?('Sidekiq::Senate')
        Sidekiq::Senate
      else
        Senate
      end
    end

    ##
    # Fake Senate class to guard against undefined constant errors.
    # @private
    class Senate
      def leader?
        false
      end
    end
  end
end
