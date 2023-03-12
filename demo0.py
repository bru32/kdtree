# Find nearest neighbour using KD-Tree
# 12 March 2023
# Bruce Wernick

dim = 2 # number of coordinates

class Node:
  def __init__(self, coord):
    self.coord = coord
    self.left = None
    self.right = None

def make_tree(arr, depth=0):
  n = len(arr)
  if n == 0: return
  ax = depth % dim
  arr.sort(key=lambda p:p[ax])
  m = n // 2
  np = Node(arr[m])
  np.left = make_tree(arr[:m], depth+1)
  np.right = make_tree(arr[m+1:], depth+1)
  return np

def print_tree(np):
  if not np: return
  print(np.coord, end=",")
  print_tree(np.left)
  print_tree(np.right)

def calc_dist(a, b):
  """ squared to improve speed """
  dist = 0
  for i in range(dim):
    dist += (a[i]-b[i])**2
  return dist

def find_nn(np, cp):
  """ find nearest neighbor to cp
  """
  def nn_loop(np, depth=0):
    nonlocal mindist, best
    if not np: return
    dist = calc_dist(np.coord, cp)
    if dist < mindist:
      best = np.coord
      mindist = dist
    ax = depth % dim
    target = cp[ax]
    plane = np.coord[ax]
    # logical search
    if target <= plane:
      nn_loop(np.left, depth+1)
    else:
      nn_loop(np.right, depth+1)
    if (target - plane)**2 <= mindist:
      # check the other side of the plane
      if target <= plane:
        nn_loop(np.right, depth+1)
      else:
        nn_loop(np.left, depth+1)
  best = None
  mindist = float("inf")
  nn_loop(np)
  return mindist, best


# ---------------------------------------------------------

if __name__ == "__main__":
  # Example.
  # Given a list of 2D coordinates, find the nearest point to (4,8).
  # data points from this pretty good article
  # https://gopalcdas.com/2017/05/24/construction-of-k-d-tree-and-using-it-for-nearest-neighbour-search/
  # The answer is: (6,8) dist=4
  arr = [(1,3),(1,8),(2,2),(2,10),(3,6),(4,1),(5,4),(6,8),(7,4),
    (7,7),(8,2),(8,5),(9,9)]
  root = make_tree(arr)
  print_tree(root)
  print()
  dist, nn = find_nn(root, (4,8))
  print("nearest =", nn)
