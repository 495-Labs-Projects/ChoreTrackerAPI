class ChoreSerializer < ActiveModel::Serializer
  attributes :id, :child_id, :task_id, :due_on, :completed
end
