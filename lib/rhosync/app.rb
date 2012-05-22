module Rhosync
  class App < Model
    field :name, :string
    set   :users, :string
    attr_reader :delegate
    validates_presence_of :name

    @@sources = []

    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        super(fields)
      end
    end
    
    def can_authenticate?
      self.delegate && self.delegate.singleton_methods.include?("authenticate")
    end

    def authenticate(login, password, session)
      if self.delegate && self.delegate.authenticate(login, password, session)
        user = User.load(login) if User.is_exist?(login)
        if not user
          user = User.create(:login => login)
          users << user.id
        end
        return user
      end
    end
    
    def delegate
      @delegate.nil? ? Object.const_get(camelize(self.name)) : @delegate
    end

    def delete
      @@sources = []
      super
    end

    def delete_sources
      @@sources = []
    end
    
    def partition_sources(partition,user_id)
      names = []
      @@sources.each do |source|
        s = Source.load(source,{:app_id => self.name,
          :user_id => user_id})
        if s.partition == partition
          names << s.name
        end
      end
      names
    end
    
    def store_blob(obj,field_name,blob)
      self.delegate.send :store_blob, obj,field_name,blob
    end

    def sources
      @@sources.uniq!
      # Sort sources array by priority
      @@sources = @@sources.sort_by { |s| Source.load(s, {:app_id => self.name, :user_id => '*'}).priority }
    end
  end
end