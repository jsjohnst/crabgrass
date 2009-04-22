=begin

 WikiController

 This is the controller for the in-place wiki editor, not for the
 the wiki page type (wiki_page_controller.rb).

 Everything here is entirely ajax, for now.

=end

class WikiController < ApplicationController
  
  include ControllerExtension::WikiRenderer
  
  before_filter :login_required, :except => [:show]
  before_filter :fetch_wiki
  
  # show the rendered wiki
  def show
    @wiki.render_html{|body| render_wiki_html(body, @group.name)}
  end
  
  # show the entire edit form
  def edit
    if @public and @private
      @private.lock(Time.now, current_user)
      @public.lock(Time.now, current_user)
    else
      @wiki.lock(Time.now, current_user)
    end
  end
  
  # a re-edit called from preview, just one area.
  def edit_area
    return render(:action => 'done') if params[:close]
  end
  
  # save the wiki show the preview
  def save
    return render(:action => 'done') if params[:cancel]
    begin
      @wiki.smart_save!(:body => params[:body], 
        :user => current_user, :version => params[:version])
      @wiki.unlock if @wiki.locked_by?(current_user)
      @wiki.render_html{|body| render_wiki_html(body, @group.name)}
    rescue Exception => exc
      @message = exc.to_s
      return render(:action => 'error')
    end    
  end
  
  # unlock everything and show the rendered wiki
  def done
    if @public and @private
      @private.unlock if @private.locked_by?(current_user)
      @public.unlock if @public.locked_by?(current_user)
      if @private.body.nil? or @private.body == ''
        @wiki = @public
      else
        @wiki = @private
      end
    else
      @wiki.unlock if @wiki.locked_by?(current_user)
    end
  end

  protected
  
  def fetch_wiki
    if params[:wiki_id] and !params[:profile_id]
      profile = @group.profiles.find_by_wiki_id(params[:wiki_id])
      @wiki = profile.wiki || profile.create_wiki
    elsif params[:profile_id]
      @profile = @group.profiles.find(params[:profile_id])
      @public = @group.profiles.public.wiki || @group.profiles.public.create_wiki
      @private = @group.profiles.private.wiki || @group.profiles.private.create_wiki
      
      @wiki = @public if params[:wiki_id] == @public.id.to_s
      @wiki = @private if params[:wiki_id] == @private.id.to_s
    end 
  end

  def authorized?    
    @group = Group.find(params[:group_id])
    logged_in? and current_user.member_of?(@group)
  end    
  
end
