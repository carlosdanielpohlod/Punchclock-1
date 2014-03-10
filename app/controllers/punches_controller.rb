class PunchesController < InheritedResources::Base

  before_action :authenticate_user!
  load_and_authorize_resource except: [:create]
  before_action :user_projects

  def index
    @punches_filter_form = PunchesFilterForm.new(params[:punches_filter_form])
    @search = @punches_filter_form.apply_filters(scopped_punches).search(params[:q])

    @search.sorts = 'from desc' if @search.sorts.empty?
    @punches = @search.result.decorate
    index!
  end

  def import_csv
    current_user.import_punches import_csv_params[:archive].path
    redirect_to punches_path, notice: "Finished importing punches."
  rescue => e
    redirect_to punches_path, alert: "Error while importing punches."
  end

  def new
    @punch = Punch.new
  end

  def edit
    @punch = Punch.find(params[:id])
  end

  def create
    @punch = Punch.new(punch_params)
    @punch.company_id = current_user.company_id
    @punch.user_id = current_user.id

    if @punch.save
      flash[:notice] = "Punch created successfully!"
      redirect_to punches_path
    else
      render action: :new
    end
  end

  def update
    @punch = scopped_punches.find params[:id]
    authorize! :update, @punch
    if @punch.update(punch_params)
      flash[:notice] = "Punch updated successfully!"
      redirect_to punches_path
    else
      render action: :edit
    end
  end

  private
  def punch_params
    allow = [:id, :from_time, :to_time, :when_day, :project_id, :attachment, :remove_attachment, :comment]
    params.require(:punch).permit(allow)
  end

  def verify_ownership
    @punch = Punch.find params[:id]
    head 403 unless @punch.user_id == current_user.id
  end

  def user_projects
    @projects = current_user.company.projects
  end

  def scopped_punches
    current_user.is_admin? ? current_user.company.punches : current_user.punches
  end

  def import_csv_params
    params.require(:archive_csv).permit(:archive)
  end
end
