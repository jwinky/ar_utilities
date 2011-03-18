module ActiveRecord
  class CannotDestroy < Exception
    attr_accessor :records

    def initialize(records)
      self.records = records
    end
  end

  module TransactionalDestroyAll
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Destroy all records by instantiating each record and calling #destroy.  All models are
      # destroyed inside of a transaction for safety.  Callbacks are triggered.
      #
      # Returns the collection of objects that were destroyed; each will be frozen to reflect that
      # no changes should be made.
      #
      # If one or more object(s) cannot be destroyed (e.g. due to a before_destroy callback) then the
      # transaction is rolled back and ActiveRecord::CannotDestroy is raised.
      def destroy_all!(find_options = {})
        transaction do
          destroyed = find(:all, find_options).group_by { |object| object.destroy != false }
          raise CannotDestroy.new(destroyed[false]) if destroyed[false]
          destroyed[true]
        end
      end
    end
  end
end

ActiveRecord::Base.include ActiveRecord::TransactionalDestroyAll