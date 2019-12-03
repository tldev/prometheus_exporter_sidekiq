require "prometheus_exporter_sidekiq/version"

module PrometheusExporterSidekiq
  TYPE = "sidekiq_global_stats"
  class Error < StandardError; end

  def self.type
    TYPE
  end
end
