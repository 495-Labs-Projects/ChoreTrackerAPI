module Api::V1
  class ChildSerializer < ActiveModel::Serializer
    attributes :id, :name, :points_earned, :active, :completed_chores, :pending_chores

    def completed_chores
      object.chores.done.map do |chore|
        ChoreSerializer.new(chore)
      end
    end

    def pending_chores
      object.chores.pending.map do |chore|
        ChoreSerializer.new(chore)
      end
    end
    
  end
end
