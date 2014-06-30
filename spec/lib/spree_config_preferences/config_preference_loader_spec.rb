require 'spec_helper'

describe Spree::ConfigPreferenceLoader do

  before do
    TestConfiguration.any_instance.stub(preference_store: Spree::Preferences::InMemoryStore.instance)
    Spree::Preferences::InMemoryStore.instance.instance_variable_set(:@config_hash, HashWithIndifferentAccess.new)
  end

  describe ".load" do
    let(:config_file) { File.join(File.dirname(__FILE__), '../../fixtures/test_config.yml') }

    subject { Spree::ConfigPreferenceLoader.load(config_file) }

    context "current environment" do
      it "loads the string preference" do
        subject
        TestConfiguration.new[:string_preference].should eq 'loaded from fixture'
      end
    end

    context "environment not present in configuration file" do
      before { Rails.stub(env: ActiveSupport::StringInquirer.new("development")) }

      it "doesn't load the string preference" do
        subject
        TestConfiguration.new[:string_preference].should be_nil
      end
    end
  end

  describe ".load_model_preferences" do
    let(:config_file) { File.join(File.dirname(__FILE__), '../../fixtures/test_model_config.yml') }

    subject { Spree::ConfigPreferenceLoader.load_model_preferences(config_file) }

    context "model is found" do
      let(:config_model) { TestConfiguration.new }

      context "current environment" do
        before { TestConfiguration.should_receive(:find).with(55).and_return(config_model) }

        it "loads the string preference" do
          subject
          config_model[:string_preference].should eq 'loaded from fixture'
        end
      end

      context "environment not present in configuration file" do
        before { Rails.stub(env: ActiveSupport::StringInquirer.new("development")) }

        it "doesn't load the string preference" do
          subject
          config_model[:string_preference].should be_nil
        end
      end
    end

    context "model is not found" do
      let(:active_record_error) { ActiveRecord::RecordNotFound.new }

      before { TestConfiguration.should_receive(:find).with(55).and_raise(active_record_error) }

      context "current environment" do
        it "handles the raised ActiveRecord error" do
          Spree::ConfigPreferenceLoader.should_receive(:handle_activerecord_error).with(active_record_error)
          subject
        end
      end

      context "production environment" do
        before { Rails.stub(env: ActiveSupport::StringInquirer.new("production")) }

        it "re-raises the error" do
          expect { subject }.to raise_error(active_record_error)
        end
      end
    end
  end

  describe ".load_environment_agnostic_preferences" do
    let(:config_file) { File.join(File.dirname(__FILE__), '../../fixtures/test_env_agnostic_config.yml') }

    subject { Spree::ConfigPreferenceLoader.load_environment_agnostic_preferences(config_file) }

    context "current environment" do
      it "loads the string preference" do
        subject
        TestConfiguration.new[:string_preference].should eq 'loaded from fixture'
      end
    end

    context "any other Rails environment" do
      before { Rails.stub(env: ActiveSupport::StringInquirer.new("development")) }

      it "loads the string preference" do
        subject
        TestConfiguration.new[:string_preference].should eq 'loaded from fixture'
      end
    end
  end
end
