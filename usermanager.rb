class User
  def initialize()
    @roles = []
    @tempban = [false, Time.now.to_i - 100]
  end

  def permrole(name)
    # Add perma role
  end

  def temprole(name, iDuration)
    # Add temp role
  end

  def unrole(name)
    # Remove role
  end

  def tempban(iDuration)
    # Ban temporarily
  end

  def update()
    # Return all update stats
  end
end
