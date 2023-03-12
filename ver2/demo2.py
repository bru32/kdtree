# demo2

import heapq

dim = 2
best = None
mindist = float("inf")

class MinHeap:
  def __init__(self):
    self.items = []
  def clear(self):
    self.items = []
  def empty(self):
    return len(self.items) == 0
  def push(self, priority, item):
    heapq.heappush(self.items, (priority, item))
  def pop(self):
    return heapq.heappop(self.items)

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
  node = Node(arr[m])
  node.left = make_tree(arr[:m], depth+1)
  node.right = make_tree(arr[m+1:], depth+1)
  return node

def calc_dist(a, b):
  dist = 0
  for i in range(dim):
    dist += (a[i]-b[i])**2
  return dist

def find_all(np, cp, depth=0):
  if not np: return
  ax = depth % dim
  dist = calc_dist(np.coord, cp)
  pq.push(dist, np.coord)
  find_all(np.left, cp, depth+1)
  find_all(np.right, cp, depth+1)

def find_nn(np, cp, depth=0):
  global best, mindist
  if not np: return
  dist = calc_dist(np.coord, cp)
  if dist < mindist:
    best = np.coord
    mindist = dist
  pq.push(dist, np.coord)
  ax = depth % dim
  target = cp[ax]
  plane = np.coord[ax]
  if target <= plane:
    find_nn(np.left, cp, depth+1)
  else:
    find_nn(np.right, cp, depth+1)
  if (target - plane)**2 <= mindist:
    if target <= plane:
      find_nn(np.right, cp, depth+1)
    else:
      find_nn(np.left, cp, depth+1)


arr = [(1,3),(1,8),(2,2),(2,10),
       (3,6),(4,1),(5,4),(6,8),
       (7,4),(7,7),(8,2),(8,5),
       (9,9)]

root = make_tree(arr)

target = (4,8)
pq = MinHeap()
find_all(root, target)
print('distance of all nodes from target')
while not pq.empty():
  print(pq.pop())
print()

pq.clear()
find_nn(root, target)
print('Nearest: ', best)
print()

print('nearest 3 nodes from target')
count = 0
while not pq.empty() and count < 3:
  print(pq.pop())
  count += 1
print()
