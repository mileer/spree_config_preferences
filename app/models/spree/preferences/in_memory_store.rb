module Spree::Preferences
  class InMemoryStore < Store
    def initialize
      super
    end

    def exist?(key)
      exists_in_config?(key) || super(key)
    end

    def get(key)
      exists_in_config?(key) ? config[key] : super(key) { }
    end

    def set(key, value)
      return if exists_in_config?(key)
      super(key, value)
    end

    def delete(key)
      return if exists_in_config?(key)
      super(key)
    end

    def add_config_values!(config_values)
      config.merge!(config_values)
    end

    private

    def config
      @config_hash ||= HashWithIndifferentAccess.new
    end

    def exists_in_config?(key)
      config.key?(key)
    end

  end
end
