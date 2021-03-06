require File.expand_path('../../spec_helper', __FILE__)

permutations =
  %w(mock instance_of strong).permutation.to_a.
  map { |parts| parts.join('.') }

permutations.each do |permutation|
  describe permutation, is_mock: true, is_instance_of: true, is_strong: true do
    include_context 'mock + instance_of + strong'

    define_method(:double_definition_creator_for) do |object, &block|
      eval(permutation + '(object, &block)')
    end
  end
end
