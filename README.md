# ChoreTracker API Lab

### Objective

In this lab we will be creating an RESTful API version of the ChoreTracker application, which means there are no need for views (just controller and model code). There will be 4 things that will be covered in this lab:

1. Creating the API itself
2. Documenting the API with swagger docs
3. Serialization Customizations
4. Stateless authentication for the API

### Instructions

#### Building the API

1. We will not be using any starter code for this application since everything will be built from scratch to help you understand the full process. First of all create a new rails application using the api flag and call it ChoreTrackerAPI. THe api flag allows rails to know how the application is intended to be used and will make sure to set up the right things in order to make the application RESTful.

```
$ rails new ChoreTrackerAPI --api
```

2. Just as the ChoreTracker that you have build before there will be 3 main entities to the ChoreTracker application, please review the old lab if you want any clarifications on the ERD. Based on these specifications, please generate all the models with all the proper fields and then run ```rake db:migrate```. This step should be the same as if you were building a regular rails application. (ex. ```rails generate model Child first_name:string last_name:string active:boolean```)
  - Child
    - first_name (string)
    - last_name (string)
    - active (boolean)
  - Task
    - name (string)
    - points (integer)
    - active (boolean)
  - Chore
    - child_id (integer)
    - task_id (integer)
    - due_on (date)
    - completed (boolean)

3. Now add in the model code below for each of the models. The code here is exactly the same as what you have done in the old ChoreTracker Application, which is why we won't require you to rewrite everything!

```ruby
class Child < ApplicationRecord
  has_many :chores
  has_many :tasks, through: :chores

  validates_presence_of :first_name, :last_name

  scope :alphabetical, -> { order(:last_name, :first_name) }
  scope :active, -> {where(active: true)}

  def name
    return first_name + " " + last_name
  end

  def points_earned
    self.chores.done.inject(0){|sum,chore| sum += chore.task.points}
  end 
end
```

```ruby
class Task < ApplicationRecord
  has_many :chores
  has_many :children, through: :chores

  validates_presence_of :name
  validates_numericality_of :points, only_integer: true, greater_than_or_equal_to: 0

  scope :alphabetical, -> { order(:name) }
  scope :active, -> {where(active: true)}
end
```

```ruby
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
```










