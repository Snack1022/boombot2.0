class User
  def initialize()
    @roles = []
    @tempban = [false, Time.now.to_i - 100]
  end

  def permrole(name)
    @roles.push([name, 'perm'])
  end

  def temprole(name, iDuration)
    @roles.push([name, iDuration])
  end

  def unrole(name)
    @roles.each do |r|
      if r[0] == name
        @roles.delete(r)
      end
    end
  end

  def tempban(iDuration)
    @tempban = [true, iDuration]
  end

  def update()
    # Return all updated stats
    # TODO: PRIO1: Install Update Filter
  end

  def roles()
    return @roles
  end


end
