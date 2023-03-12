# KD-Tree
# basic algorithm - Wikipedia
# 11 March 2023
# Bruce Wernick

import math
import heapq

dim = 2 # dimension of coord

# globals for find_nn
best = None
mindist = float("inf")


class MaxHeap:
  def __init__(self):
    self.items = []

  def clear(self):
    self.items = []

  def empty(self):
    return len(self.items) == 0

  def put(self, item, priority):
    heapq.heappush(self.items, (-priority, item))

  def get(self):
    item, priority = heapq.heappop(self.items)
    return (item, -priority)


class MinHeap:
  """ minimim priority queue
  """
  def __init__(self):
    self.items = []

  def clear(self):
    self.items = []

  def empty(self):
    return len(self.items) == 0

  def put(self, item, priority):
    heapq.heappush(self.items, (priority, item))

  def get(self):
    return heapq.heappop(self.items)


class Node:
  def __init__(self, coord):
    self.coord = coord
    self.left = None
    self.right = None


def calc_dist(a, b):
  """ return distance
  """
  dist = 0
  for i in range(2):
    dist += (a[i]-b[i])**2 # distance squared
    #dist += abs(a[i]-b[i]) # manhatten distance
  return dist


def show_tree(np):
  if not np: return
  print(np.coord, end=",")
  show_tree(np.left)
  show_tree(np.right)

def make_tree(arr, depth=0):
  """ make a kd-tree
  """
  n = len(arr)
  if n == 0: return
  ax = depth % dim
  arr.sort(key=lambda p:p[ax]) # sort by axis
  m = n // 2 # median
  node = Node(arr[m])
  node.left = make_tree(arr[:m], depth+1)
  node.right = make_tree(arr[m+1:], depth+1)
  return node

def find_all(node, coord, depth=0):
  """ find the distance from all nodes
  """
  if not node: return
  ax = depth % dim
  dist = calc_dist(node.coord, coord)
  pq.put(node.coord, dist)
  find_all(node.left, coord, depth+1)
  find_all(node.right, coord, depth+1)

def find_nn(node, coord, depth=0):
  """ find node nearest to coord
  """
  global best, mindist
  if not node: return

  dist = calc_dist(node.coord, coord)
  if dist < mindist:
    best = node.coord
    mindist = dist

  pq.put(node.coord, dist)

  ax = depth % dim
  target = coord[ax]
  np = node.coord[ax]

  # logical check
  if target <= np:
    find_nn(node.left, coord, depth+1)
  else:
    find_nn(node.right, coord, depth+1)

  # check the other side of the plane
  if (target - np)**2 < mindist:
    if target <= np:
      find_nn(node.right, coord, depth+1)
    else:
      find_nn(node.left, coord, depth+1)


# ----------------------------------------------------------------------

if __name__ == "__main__":


  # Example.
  # Given a list of 2D coordinates, find the nearest point to (4,8).
  # data points from this pretty good article
  # https://gopalcdas.com/2017/05/24/construction-of-k-d-tree-and-using-it-for-nearest-neighbour-search/
  # The answer is: (6,8) dist=4
  arr = [(1,3),(1,8),(2,2),(2,10),
         (3,6),(4,1),(5,4),(6,8),
         (7,4),(7,7),(8,2),(8,5),
         (9,9)]

  root = make_tree(arr)
  show_tree(root)
  print("\n")

  target = (4,8)

  pq = MinHeap()

  find_all(root, target)
  print("find all")
  while not pq.empty():
    print(pq.get())
  print()

  pq.clear()
  find_nn(root, target)
  print("find nn")
  print(f"{best=}, {mindist=:0.2f}")
  print()

  # show 1st n items in pqueue after find_nn
  n = 3
  i = 0
  while not pq.empty():
    i += 1
    print(i, pq.get())
    if i >= n:
      break
  print()
