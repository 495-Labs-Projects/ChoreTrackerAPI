class Chore < ApplicationRecord
  belongs_to :child
  belongs_to :task

  # Validations
  validates_date :due_on
  
  # Scopes
  scope :by_task, -> { joins(:task).order('tasks.name') }
  scope :chronological, -> { order('due_on') }
  scope :done, -> { where('completed = ?', true) }
  scope :pending, -> { where('completed = ?', false) }
  scope :upcoming, -> { where('due_on >= ?', Date.today) }
  scope :past, -> { where('due_on < ?', Date.today) }
  
  # Other methods
  def status
    self.completed ? "Completed" : "Pending"
  end
end