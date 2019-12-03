# frozen_string_literal: true

# collects stats from currently running process
module PrometheusExporterSidekiq
  class Instrumentation
    GLOBAL_STATS = %i[failed processed retry_size dead_size scheduled_size workers_size].freeze
    SIDEKIQ_GLOBAL_METRICS = [
      { name:      :sidekiq_workers_size,
        type:      :gauge,
        docstring: 'Total number of workers processing jobs', },
      { name:      :sidekiq_dead_size,
        type:      :gauge,
        docstring: 'Total Dead Size', },
      { name:      :sidekiq_enqueued,
        type:      :gauge,
        docstring: 'Total Size of all known queues',
        labels:    %i[queue], },
      { name:      :sidekiq_queue_latency,
        type:      :summary,
        docstring: 'Latency (in seconds) of all queues',
        labels:    %i[queue], },
      { name:      :sidekiq_failed,
        type:      :gauge,
        docstring: 'Number of job executions which raised an error', },
      { name:      :sidekiq_processed,
        type:      :gauge,
        docstring: 'Number of job executions completed (success or failure)', },
      { name:      :sidekiq_retry_size,
        type:      :gauge,
        docstring: 'Total Retries Size', },
      { name:      :sidekiq_scheduled_size,
        type:      :gauge,
        docstring: 'Total Scheduled Size', },
      { name:      :sidekiq_redis_connected_clients,
        type:      :gauge,
        docstring: 'Number of clients connected to Redis instance for Sidekiq', },
      { name:      :sidekiq_redis_used_memory,
        type:      :gauge,
        docstring: 'Used memory from Redis.info', },
      { name:      :sidekiq_redis_used_memory_peak,
        type:      :gauge,
        docstring: 'Used memory peak from Redis.info', },
      { name:      :sidekiq_redis_keys,
        type:      :gauge,
        docstring: 'Number of redis keys',
        labels:     %i[database], },
      { name:      :sidekiq_redis_expires,
        type:      :gauge,
        docstring: 'Number of redis keys with expiry set',
        labels:     %i[database], },
    ].freeze


    def self.start(client: nil, frequency: 30) }
      process_collector = new
      client ||= PrometheusExporter::Client.default

      stop if @thread

      @thread = Thread.new do
        while true
          begin
            metric = process_collector.collect
            client.send_json metric
          rescue => e
            STDERR.puts("Prometheus Exporter Failed To Collect Sidekiq Stats #{e}")
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

    def initialize(metric_labels: metric_labels, sidekiq_stats: Sidekiq::Stats, sidekiq_queue: Sidekiq::Queue, senate: nil)
      @senate = senate || determine_senate
      @sidekiq_stats = sidekiq_stats
      @sidekiq_queue = sidekiq_queue

      @metric_labels = metric_labels
    end

    def collect
      metric = {}
      metric[:type] = "sidekiq_global_stats"
      metric[:metric_labels] = @metric_labels
      collect_sidekiq_stats(metric)
      metric
    end

    def collect_sidekiq_stats(_)
      current_stats = @sidekiq_stats.new
      GLOBAL_STATS.each do |stat|

      end
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
