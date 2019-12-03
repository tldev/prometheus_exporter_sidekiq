# frozen_string_literal: true

require "prometheus_exporter"
require "prometheus_exporter/server"

module PrometheusExporterSidekiq

  class Collector < PrometheusExporter::Server::TypeCollector
    MAX_PROCESS_METRIC_AGE = 60
    GAUGES = {
      sidekiq_workers_size: 'Total number of workers processing jobs',
      sidekiq_dead_size: 'Total Dead Size',
      sidekiq_enqueued: 'Total Size of all known queues',
      sidekiq_failed: 'Number of job executions which raised an error',
      sidekiq_processed: 'Number of job executions completed (success or failure)',
      sidekiq_retry_size: 'Total Retries Size',
      sidekiq_scheduled_size: 'Total Scheduled Size',
    }.freeze

    def initialize
      @process_metrics = []
    end

    def type
      PrometheusExporterSidekiq.type
    end

    def metrics
      return [] if @process_metrics.length == 0

      metrics = {}

      @process_metrics.map do |m|
        metric_key = m["metric_labels"]
        metric_key.merge!(m["custom_labels"] || {})

        GAUGES.map do |k, help|
          k = k.to_s
          if !m[k].nil?
            g = metrics[k] ||= PrometheusExporter::Metric::Gauge.new(k, help)
            g.observe(v, metric_key)
          end
        end
      end

      metrics.values
    end

    def collect(obj)
      now = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

      obj["created_at"] = now

      @process_metrics.delete_if do |current|
        current["created_at"] + MAX_PROCESS_METRIC_AGE < now
      end

      @process_metrics << obj
    end
  end
end
