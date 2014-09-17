module SpreeConfigPreferences
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_config_preferences'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      if Rails.configuration.respond_to? :spree_config_preferences_preference_files
        Rails.configuration.spree_config_preferences_preference_files.each do |pref_file|
          Spree::ConfigPreferenceLoader.load(pref_file)
        end
      end

      if Rails.configuration.respond_to? :spree_config_preferences_model_preference_files
        Rails.configuration.spree_config_preferences_model_preference_files.each do |pref_file|
          Spree::ConfigPreferenceLoader.load_model_preferences(pref_file)
        end
      end

      if Rails.configuration.respond_to? :spree_config_preferences_environment_agnostic_preference_files
        Rails.configuration.spree_config_preferences_environment_agnostic_preference_files.each do |pref_file|
          Spree::ConfigPreferenceLoader.load_environment_agnostic_preferences(pref_file)
        end
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
