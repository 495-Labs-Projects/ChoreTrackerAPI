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

2. Just as the ChoreTracker that you have build before there will be 3 main entities to the ChoreTracker application.