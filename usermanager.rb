class User
  def initialize(id)
    @userid = id # For DB reasons
    @roles = []
    @tempban = [false, 0]
    @lastupdatestat = [@roles, @tempban]
    @warnings = []
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

  def roles()
    return @roles
  end

  def banstatus()
    return @tempban
  end

  def tempban(time)
    @tempban = [true, time]
  end

  # Update-Method has been cancelled. Relying on set/gets now.

  def warn(msg)
    @warnings.push([Time.now, msg])
  end

  def getwarns
    return @warnings
  end

  def undowarn(id)
    begin
      @warnings.delete_at(id)
    rescue
      return false
    end
    return true
  end
end
