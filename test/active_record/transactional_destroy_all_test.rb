require 'test_helper'

class CreateAmodels < ActiveRecord::Migration
  def self.up
    create_table :amodels, :force => true do |t|
      t.boolean :sticky, :null => false, :default => false
    end
  end
end

CreateAmodels.up

class Amodel < ActiveRecord::Base
  before_destroy :false_if_sticky

  private

  def false_if_sticky
    false if sticky
  end
end

class TransactionalDestroyAllTest < ActiveSupport::TestCase
  context "Three models" do
    setup do
      @models = Array.new(3) { Amodel.create! }
    end

    context "destroy_all!" do
      should "destroy all models and return an array containing all the objects" do
        assert_changes "Amodel.count" => [3, 0] do
          result = Amodel.destroy_all!
          assert_equal @models, result
          assert result.all?(&:frozen?)
        end
      end
    end

    context "when one model cannot be destroyed" do
      setup { @models[1].update_attribute(:sticky, true) }

      context "destroy_all!" do
        should "raise ActiveRecord::CannotDestroy and not make any changes" do
          assert_no_changes "Amodel.count" do
            the_exception = nil

            begin
              Amodel.destroy_all!
            rescue ActiveRecord::CannotDestroy => e
              the_exception = e
            ensure
              assert_not_nil the_exception
              assert_equal [@models[1]], the_exception.records
            end
          end
        end
      end
    end
  end

end
