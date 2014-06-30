require 'spec_helper'

describe Spree::Preferences::InMemoryStore do

  let(:configuration_key)       { "configuration_key" }
  let(:falsy_configuration_key) { "falsy_config_key" }
  let(:config_file)             { File.join(File.dirname(__FILE__), '../../fixtures/config.yml') }

  subject { Spree::Preferences::InMemoryStore.instance }

  before do
    subject.instance_variable_set(:@config_hash, HashWithIndifferentAccess.new)
  end

  describe "#get" do

    let(:configuration_value) { "database value" }

    context "config file contains key" do
      context "the value is falsy" do
        before do
          subject.add_config_values!(YAML.load_file(config_file))
          Spree::Preference.create!(key: falsy_configuration_key, value: configuration_value, value_type: "string")
        end

        it "uses the default Spree preference lookup" do
          subject.get(falsy_configuration_key).should be_false
        end
      end

      context "the value is not falsy" do
        before do
          subject.add_config_values!(YAML.load_file(config_file))
          Spree::Preference.create!(key: configuration_key, value: configuration_value, value_type: "string")
        end

        it "returns the value for the key that was loaded from the config file" do
          subject.get(configuration_key).should eq "value"
        end
      end
    end

    context "config file doesn't contain key" do
      let(:configuration_value) { "database value" }

      before do
        Spree::Preference.create!(key: configuration_key, value: configuration_value, value_type: "string")
      end

      it "uses the default Spree preference lookup" do
        subject.get(configuration_key).should eq configuration_value
      end
    end
  end

  describe "#set" do

    let(:configuration_value) { "value" }
    let(:configuration_type) { "string" }
    let(:new_configuration_value) { "new value" }

    context "config file contains key" do
      before do
        subject.add_config_values!(YAML.load_file(config_file))
      end

      it "does not change the value in memory" do
        subject.set(configuration_key, new_configuration_value, configuration_type)
        subject.get(configuration_key).should eq configuration_value
      end

      it "does not save the value in the database" do
        expect do
          subject.set(configuration_key, new_configuration_value, configuration_type)
        end.to_not change(Spree::Preference, :count)
      end
    end

    context "config file doesn't contain key" do
      let(:configuration_value) { "database value" }

      it "uses the default Spree preference set" do
        expect do
          subject.set(configuration_key, configuration_value, configuration_type)
        end.to change(Spree::Preference, :count).by(1)

        subject.get(configuration_key).should eq configuration_value
      end
    end
  end

  describe "#exist?" do

    context "config file contains key" do
      before do
        subject.add_config_values!(YAML.load_file(config_file))
      end

      it "returns true" do
        subject.exist?(configuration_key).should be_true
      end
    end

    context "config file doesn't contain key" do
      it "returns false" do
        subject.exist?("unknown_key").should be_false
      end
    end
  end

  describe "#delete" do
    context "config file contains key" do
      before do
        subject.add_config_values!(YAML.load_file(config_file))
      end

      it "doesn't delete the entry in the config_hash" do
        subject.delete(configuration_key)
        subject.exist?(configuration_key).should be_true
      end
    end

    context "config file doesn't contain key" do
      it "calls delete on the parent" do
        Spree::Preference.should_receive(:find_by_key).with(configuration_key)
        subject.delete(configuration_key)
      end
    end
  end

  describe "#add_config_values!" do
    context "config file contains key" do
      let(:replaced_value) { "replacing value" }

      before do
        subject.add_config_values!(YAML.load_file(config_file))
      end

      it "replaces values that already exist" do
        subject.add_config_values!({configuration_key: replaced_value})

        subject.get(configuration_key).should eq replaced_value
      end
    end

    context "config file doesn't contain key" do
      let(:new_value) { "new value" }

      it "adds new values when the don't exist" do
        subject.add_config_values!({configuration_key: new_value})

        subject.get(configuration_key).should eq new_value
      end
    end
  end

end
