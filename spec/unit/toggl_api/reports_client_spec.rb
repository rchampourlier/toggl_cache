# frozen_string_literal: true
require "spec_helper"
require "toggl_api/reports_client"

describe TogglAPI::ReportsClient do
  let(:options) { {} }
  let(:expected_api_call_url) { "https://toggl_api_token:api_token@toggl.com/reports/api/v2/details?page=1&user_agent=TogglAPI" }

  let(:api_response_status) { 200 }
  let(:api_response_body) do
    {
      total_count: total_count,
      data: data_page1
    }.to_json
  end
  let(:total_count) { 0 }
  let(:data_page1) do
    50.times.map { { id: 1 } } # faking 50 entries
  end

  before do
    stub_request(:get, expected_api_call_url)
      .with(headers: { "Content-Type" => "application/json" })
      .to_return(status: api_response_status, body: api_response_body, headers: {})
  end

  describe "#fetch_reports(params, &block)" do

    context "only 1 page" do
      let(:total_count) { 50 }

      it "fetches the data only once" do
        described_class.new.fetch_reports(options) {}
        # It will fail if it fetches several times because
        # the second request, with page=2, is not mocked.
      end

      it "passes the received data to the specified block" do
        results = described_class.new.fetch_reports(options) do |reports|
          expect(reports.count).to eq(50)
        end
      end
    end

    context "several pages" do
      let(:total_count) { 60 }
      let(:data_page2) do
        10.times.map { { id: 2 } } # faking 10 entries
      end

      before do
        api_response_body_page2 = {
          total_count: total_count,
          data: data_page2
        }.to_json
        stub_request(:get, expected_api_call_url.gsub('page=1', 'page=2'))
          .with(headers: { "Content-Type" => "application/json" })
          .to_return(status: api_response_status, body: api_response_body_page2, headers: {})
      end

      it "fetches the additional pages" do
        total_count = 0
        results = described_class.new.fetch_reports(options) do |reports|
          total_count += reports.count
        end
        expect(total_count).to eq(60)
      end
    end

    context "receiving non-successful response" do
      let(:api_response_status) { 500 }

      it "raises a TogglAPI::Error" do
        expect { described_class.new.fetch_reports(options) {} }
          .to raise_error(TogglAPI::Error)
      end
    end
  end
end
