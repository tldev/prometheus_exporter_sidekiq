RSpec.describe PrometheusExporterSidekiq do
  it "has a version number" do
    expect(PrometheusExporterSidekiq::VERSION).not_to be nil
  end

  describe "#type" do
    it "has as type" do
      expect(described_class.type).to eq("sidekiq_global_stats")
    end
  end
end
