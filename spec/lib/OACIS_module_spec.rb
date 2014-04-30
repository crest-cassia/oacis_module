require 'spec_helper'

describe "OACIS_module" do

  describe "#initialize" do

    before(:each) do
      @sim = FactoryGirl.create(:simulator, parameter_sets_count: 2, runs_count: 0, finished_runs_count: 2, analyzers_count: 1, run_analysis: false, analyzers_on_parameter_set_count: 1, run_analysis_on_parameter_set: false)
      @valid_attr = {"_target"=>{"Simulator"=>@sim.to_param}}
    end

    it "needs an argument with Hash[\"_target""][\"Simulator\"]=sim.id" do

      expect {
        oacis_module = OacisModule.new(@valid_attr)
      }.not_to raise_error
      class OacisModule
        def target_sim
          @target_simulator
        end
      end
      OacisModule.new(@valid_attr).target_sim.should eq @sim
    end

    context "when [\"_target""][\"Simulator\"] is invalid" do

      it "raise error" do
        @valid_attr["_target"]["Simulator"]="0123456789"
        expect {
          OacisModule.new(@valid_attr)
        }.to raise_error
      end
    end

    it "perses json values to hash" do

      class OacisModule
        def input_data
          @input_data
        end
      end
      data = [{"type"=>"String"},{"value"=>12345}]
      @valid_attr["json"]=data.to_json
      oacis_module = OacisModule.new(@valid_attr)
      oacis_module.input_data["json"].should eq data
    end
  end
end
