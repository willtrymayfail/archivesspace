class RecordsController < ApplicationController

  def resource
    @resource = JSONModel(:resource).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object"])
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
    @tree = JSONModel(:resource_tree).find(nil, :resource_id => @resource.id, :repo_id => params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.title, "#", "resource"]
    ]
  end

  def archival_object
    @archival_object = JSONModel(:archival_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "container_locations", "digital_object"])
    @resource = JSONModel(:resource).find_by_uri(@archival_object['resource']['ref'], :repo_id => params[:repo_id])
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
    @children = JSONModel::HTTP::get_json("/repositories/#{params[:repo_id]}/archival_objects/#{@archival_object.id}/children")

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@resource.title, url_for(:controller => :records, :action => :resource, :id => @resource.id, :repo_id => @repository.id), "resource"],
    ]

    ao = @archival_object
    while ao['parent'] do
      ao = JSONModel(:archival_object).find(JSONModel(:archival_object).id_for(ao['parent']['ref']), :repo_id => @repository.id)
      @breadcrumbs.push([ao.title, url_for(:controller => :records, :action => :archival_object, :id => ao.id, :repo_id => @repository.id), "archival_object"])
    end

    @breadcrumbs.push([@archival_object.title, "#", "archival_object"])
  end

  def digital_object
    @digital_object = JSONModel(:digital_object).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects", "linked_instances"])
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
    @tree = JSONModel(:digital_object_tree).find(nil, :digital_object_id => @digital_object.id, :repo_id => params[:repo_id])

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, "#", "digital_object"]
    ]
  end

  def digital_object_component
    @digital_object_component = JSONModel(:digital_object_component).find(params[:id], :repo_id => params[:repo_id], "resolve[]" => ["subjects"])
    @digital_object = JSONModel(:digital_object).find_by_uri(@digital_object_component['digital_object']['ref'], :repo_id => params[:repo_id])
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
    @children = JSONModel::HTTP::get_json("/repositories/#{params[:repo_id]}/digital_object_components/#{@digital_object_component.id}/children")

    @breadcrumbs = [
      [@repository['repo_code'], url_for(:controller => :search, :action => :repository, :id => @repository.id), "repository"],
      [@digital_object.title, url_for(:controller => :records, :action => :digital_object, :id => @digital_object.id, :repo_id => @repository.id), "digital_object"],
    ]

    ao = @digital_object_component
    while ao['parent'] do
      ao = JSONModel(:digital_object_component).find(JSONModel(:digital_object_component).id_for(ao['parent']['ref']), :repo_id => @repository.id)
      @breadcrumbs.push([ao.title, url_for(:controller => :records, :action => :digital_object_component, :id => ao.id, :repo_id => @repository.id), "digital_object_component"])
    end

    @breadcrumbs.push([@digital_object_component.title, "#", "digital_object_component"])
  end

end
