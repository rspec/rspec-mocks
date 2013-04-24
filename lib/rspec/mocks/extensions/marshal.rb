module Marshal
  class << self
    def dump_with_mocks(*args)
      object = args.shift

      if ( ::RSpec::Mocks.space && !::RSpec::Mocks.space.registered?(object) ) || NilClass === object
        return dump_without_mocks(*args.unshift(object))
      end

      dump_without_mocks(*args.unshift(object.dup))
    end

    alias_method :dump_without_mocks, :dump
    undef_method :dump
    alias_method :dump, :dump_with_mocks
  end
end
