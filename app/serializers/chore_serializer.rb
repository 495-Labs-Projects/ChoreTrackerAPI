class ChoreSerializer < ActiveModel::Serializer
  attributes :id, :child_id, :task, :due_on, :completed

  def task
  	TaskPreviewSerializer.new(object.task)
  end
end
