module Api::V2
  class ChoreSerializer < ActiveModel::Serializer
    attributes :id, :child, :task, :due_on, :completed

    def child
      ChoreChildSerializer.new(object.child)
    end

    def task
      ChoreTaskSerializer.new(object.task)
    end
  end
end
