require 'spec_helper'

module RSpec
  module Mocks
    module ArgumentMatchers
      describe ArrayIncludingMatcher do
        it "describes itself properly" do
          expect(ArrayIncludingMatcher.new([1, 2, 3]).description).to eq "array_including(1,2,3)"
        end

        context "passing" do
          it "matches the same array" do
            expect(array_including(1, 2, 3)).to be === [1, 2, 3]
          end

          it "matches the same array,  specified without square brackets" do
            expect(array_including(1, 2, 3)).to be === [1, 2, 3]
          end

          it "matches the same array,  which includes nested arrays" do
            expect(array_including([1, 2], 3, 4)).to be === [[1, 2], 3, 4]
          end

          it "works with duplicates in expected" do
            expect(array_including(1, 1, 2, 3)).to be === [1, 2, 3]
          end

          it "works with duplicates in actual" do
            expect(array_including(1, 2, 3)).to be === [1, 1, 2, 3]
          end
        end

        context "failing" do
          it "fails when not all the entries in the expected are present" do
            expect(array_including(1,2,3,4,5)).not_to be === [1,2]
          end
        end
      end
    end
  end
end
