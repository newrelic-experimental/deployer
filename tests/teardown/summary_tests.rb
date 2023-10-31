require "minitest/spec"
require "minitest/autorun"
require "mocha/minitest"

require "./src/teardown/summary"

describe "Teardown::Summary" do
    let(:composer) { Teardown::Summary.new() }
    let(:deployment_name) { "example-instance" }
    let(:deploy_config_url) { "https://example.com/config.json" }

    it "should include deploy config url" do
        summary = composer.execute(depoyment_name, deploy_config_url)
        summary.must_include(deploy_config_url)
    end

    it "should include deployment name" do
        summary = composer.execute(deployment_name, deploy_config_url)
        summary.must_include(deployment_name)
    end
end