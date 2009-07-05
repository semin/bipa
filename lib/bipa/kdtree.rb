module Bipa
  class KDNode

    attr_reader   :point
    attr_accessor :left, :right

    def initialize(point)
      @point  = point
      @left   = nil
      @right  = nil
    end
  end

  class KDTree

    def initialize
      @root       = nil
      @neighbors  = []
    end

    # Insert a new point into the tree
    def insert(point)
      depth = 0
      if @root.nil?
        @root = KDNode.new(point)
      else
        current_node = @root
        begin
          tmp_node      = current_node
          discriminator = depth % point.size
          ordinate1     = point.dimension(discriminator)
          ordinate2     = tmp_node.point.dimension(discriminator)
          if ordinate1 > ordinate2
            current_node = tmp_node.right
          else
            current_node = tmp_node.left
          end
          depth += 1
        end while (current_node != nil)
        if ordinate1 > ordinate2
          tmp_node.right = KDNode.new(point)
        else
          tmp_node.left = KDNode.new(point)
        end
      end
    end

    def find_neighbor(root, depth, point, eps)
      d = depth % point.size
      if root.nil?
        nil
      elsif ((root.point - point) < eps)
        root
      elsif (point.dimension(d) > root.point.dimension(d))
        find_neighbor(root.right, depth + 1, point, eps)
      else
        find_neighbor(root.left, depth + 1, point, eps)
      end
    end

    def neighbor(point, eps=1.0e-6)
      find_neighbor(@root, 0, point, eps)
    end

    def find_neighbors(root, depth, point, range)
      d = depth % point.size
      return nil if root.nil?
      if ((point - root.point) < range)
        @results << root
      end
      if (root.point.dimension(d) > (point.dimension(d) - range))
        find_neighbors(root.left, depth + 1, point, range)
      end
      if (root.point.dimension(d) < (point.dimension(d) + range))
        find_neighbors(root.right, depth + 1, point, range)
      end
    end

    def neighbors(point, range)
      @results = []
      find_neighbors(@root, 0, point, range)
      @results
    end
  end
end
