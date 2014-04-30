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

    describe "calls create_or_restore_module_data" do

      before(:each) do

        class OacisModule

          def input_data
            @input_data
          end

          def module_dat
            @module_data
          end

          def num_iteration
            @num_iterations
          end
        end
      end

      it "update module_data" do

        data = [{"type"=>"String"},{"value"=>12345}]
	valid_attr = @valid_attr.dup
        valid_attr["json"]=data.to_json
        @oacis_module = OacisModule.new(valid_attr)
        @oacis_module.module_dat.data["_input_data"].should eq @oacis_module.input_data
        @oacis_module.module_dat.data["_status"]["iteration"].should eq 0
        @oacis_module.num_iteration.should eq 0
      end

      context "when _output.json is exists" do

        it "update module data" do

          at_temp_dir {
            data = @valid_attr.dup
            data["_status"] = {}
            data["_status"]["iteration"] = 100
            io = File.open("_output.json", "w")
            io.puts data.to_json
            io.flush
            io.close

            @oacis_module = OacisModule.new(@valid_attr)
            @oacis_module.module_dat.data["_input_data"].should eq @oacis_module.input_data
            @oacis_module.module_dat.data["_status"]["iteration"].should eq 100
            @oacis_module.num_iteration.should eq 100
          }
        end
      end

      context "when _output.json is invalid" do

        it "raise error" do

          at_temp_dir {
            data = @valid_attr.dup
            data["_status"] = {}
            data["_status"]["iteration"] = nil
            io = File.open("_output.json", "w")
            io.puts data.to_json
            io.flush
            io.close

            expect {
              OacisModule.new(@valid_attr)
            }.to raise_error
          }
        end
      end
    end
  end
end
