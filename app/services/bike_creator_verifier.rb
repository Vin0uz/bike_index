class BikeCreatorVerifier
  def initialize(b_param = nil, bike = nil)
    @b_param = b_param
    @bike = bike
  end

  def check_organization
    @bike = BikeCreatorOrganizer.new(@b_param, @bike).organized_bike
  end

  def check_example
    example_org = Organization.example
    @bike.creation_organization_id = example_org.id if @b_param.params && @b_param.params["test"]
    if @bike.creation_organization_id.present? && example_org.present?
      @bike.example = true if @bike.creation_organization_id == example_org.id
    else
      @bike.example = false
    end
    @bike
  end

  def add_phone
    @bike.phone ||= @b_param.phone if @b_param.params && @b_param.params["stolen_record"].present?
    if @bike.creation_organization.present? && @bike.creation_organization.locations.any?
      @bike.phone ||= @bike.creation_organization.locations.first.phone
    elsif @bike.creator && @bike.creator.phone.present?
      @bike.phone ||= @bike.creator.phone
    end
  end

  def stolenize
    @bike.stolen = true
    add_phone unless @bike.phone.present?
  end

  def recoverize
    @bike.abandoned = true
    stolenize
  end

  def check_stolen_and_abandoned
    if @b_param.params["stolen"]
      stolenize
    elsif @b_param.params["bike"].present? && @b_param.params["bike"]["stolen"]
      stolenize
    elsif @b_param.params["abandoned"]
      recoverize
    elsif @b_param.params["bike"].present? && @b_param.params["bike"]["abandonded"]
      recoverize
    end
  end

  def verify
    check_organization
    check_stolen_and_abandoned
    check_example
    @bike
  end
end
