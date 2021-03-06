# coding: utf-8

class Admin::TablesController < ApplicationController
  ssl_required :index, :show, :embed_map

  skip_before_filter :check_domain, :only => [:embed_map]
  skip_before_filter :browser_is_html5_compliant?, :only => [:embed_map]  
  before_filter :login_required, :except => [:embed_map]

  def index
    current_page = params[:page].nil? ? 1 : params[:page].to_i
    per_page = 30
    @tags = Tag.load_user_tags(current_user.id, :limit => 10)
    @tables = if !params[:tag_name].blank?
      Table.find_all_by_user_id_and_tag(current_user.id, params[:tag_name]).order(:id).reverse.paginate(current_page, per_page)
    else
      Table.filter({:user_id => current_user.id}).order(:id).reverse.paginate(current_page, per_page)
    end
    @tables_count  = @tables.pagination_record_count
    
    # in mb
    @quota         = current_user.quota_in_bytes / 1024 / 1024
    @database_size = current_user.db_size_in_bytes / 1024 /1024
  end

  def show
    @table = Table.find_by_identifier(current_user.id, params[:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data @table.to_csv,
          :type => 'application/zip; charset=binary; header=present',
          :disposition => "attachment; filename=#{@table.name}.zip"
      end
      format.shp do
        if shp_content = @table.to_shp
          send_data shp_content,
            :type => 'application/octet-stream; charset=binary; header=present',
            :disposition => "attachment; filename=#{@table.name}.zip"
        else
          # FIXME: Give some feedback in the UI
          redirect_to table_path(@table), :alert => "There was an error exporting the table"
        end
      end
    end
  end
  
  def embed_map
    @subdomain = request.subdomain
    @table = Table.find_by_subdomain(@subdomain, params[:id])    
    if @table.blank? || @table.private?
      head :forbidden
    else
      render :layout => false        
    end
  end
end