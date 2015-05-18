# 全局变量
# 分配给一个作业的内存块为4
MEMORY_BLOCK_MAX = 4
# 每个页面可存放10条指令
PAGE_STORE_MAX = 10
# 作业指令总数
INSTRUCTS_TOTAL = 320
# 地址空间
ADDR_SPACE = INSTRUCTS_TOTAL / PAGE_STORE_MAX

# 指令数组
insArr = []
# 当前内存中的页面
memPage = []

global =
  # 当前执行的指令的索引
  insM: 0
  # 下一步跳转方式（0 - 顺序执行，1 - 后地址部分，2 - 顺序执行, 3 - 前地址部分）
  jumpType: 0
  # 当前使用的算法
  algorithmUsing: FIFO
  # 需要更新UI中的指令队列显示
  needUpdateInstructionQueue: yes
  # 需要更新UI中的内存块
  needUpdateMemoryPages: yes
  # 从内存中被挤出去的页面
  popPage: null
  # 自动播放interval id
  autoplayIntervalId: -1
  # 总计指令读取
  insLoadTotal: 0
  # 缺页次数
  pageNotFoundTime: 0

algCount =
  # 内存中某块页面距离上次访问已经过去的指令周期（LRU算法用）
  blockLastVisited: []
  # 各个页面总计访问次数（LFU算法用）
  pageVisitedTime: []


# 初始化全局
init = (memBlockMax = 4, pageStoreMax = 10, insTotal = 320)->
  MEMORY_BLOCK_MAX = memBlockMax
  PAGE_STORE_MAX = pageStoreMax
  INSTRUCTS_TOTAL = insTotal
  ADDR_SPACE = INSTRUCTS_TOTAL / PAGE_STORE_MAX

  # 初始化insArr
  insArr = []

  # 初始化algCount
  algCount.blockLastVisited = []
  algCount.pageVisitedTime = []
  algCount.blockLastVisited.push 9999 for iter in [1..MEMORY_BLOCK_MAX]
  algCount.pageVisitedTime.push 0 for iter in [0..ADDR_SPACE]

  pushInstruction() for iter in [0..9]

  # 初始化memState
  memPage = []
  (->memPage.push null)() for eachBlockSize in [1..MEMORY_BLOCK_MAX]
  # init end
  return true

pushInstruction = ()->
# console.log global.insM
  # pushNum = Math.floor Math.random() * INSTRUCTS_TOTAL
  # insArr.push pushNum if pushNum isnt undefined
  if global.jumpType is 0 or global.jumpType is 2 then (
    insArr.push global.insM
    global.insM += 1
    global.jumpType = global.jumpType + 1
  ) else if global.jumpType is 1 then (
    global.insM = global.insM + Math.floor Math.random() * (INSTRUCTS_TOTAL - global.insM)
    insArr.push global.insM
    global.jumpType = 2
    global.insM += 1
  )
  else if global.jumpType is 3 then (
    global.insM = Math.floor Math.random() * global.insM
    insArr.push global.insM
    global.jumpType = 0
    global.insM += 1
  )

# 初始化HTML
initHTML = ->
  $('.memory-div').append('<div class="memory-block"></div>') for each in [1..MEMORY_BLOCK_MAX]
  $('.memory-block').css('height', (450 / MEMORY_BLOCK_MAX) + 'px')

# 载入指令
loadInstruction = ()->
  global.insLoadTotal += 1
  global.popPage = insArr.shift()
  pushInstruction()

# 页面载入内存
loadPage = (pageNum, pageOut, exchangeWhich)->
  ret = memPage[exchangeWhich]
  memPage[exchangeWhich] = pageNum
  ret

# 检查对应指令所在页面是否在内存中
checkPage = (insAddr) ->
  ret = no
  (
    algCount.blockLastVisited[memPage.indexOf page] += 1
    (
      algCount.blockLastVisited[memPage.indexOf page] = 0
      algCount.pageVisitedTime[page] += 1
      ret = yes
    ) if (page isnt null) and ((getPageByAddress insAddr) is page)
  ) for page in memPage
  ret

# 获取内存地址所在的页面索引
getPageByAddress = (addr) ->
  return Math.floor (addr / PAGE_STORE_MAX)

# 更新函数，用setInterval每100毫秒刷新一次
update = ()->
  if global.needUpdateInstructionQueue then (
    $('.instruction-queue').empty()
    $('.instruction-queue').append '<div class="instruction">' + insArr[index] + '</div>' for index in [0..9]
    global.needUpdateInstructionQueue = no
  );
  if global.needUpdateMemoryPages then (
    $('.memory-div').empty()
    (
      if memPage[index] isnt null then (
        $('.memory-div').append('<div class="memory-block">' + 'Page #' + memPage[index] +
        '<br />Address: ' + (memPage[index] * 10) + ' ~ ' + (memPage[index] * 10 + PAGE_STORE_MAX - 1) +
        '<br />Last visit: ' + algCount.blockLastVisited[index] +
        '<br />Page visited: ' + algCount.pageVisitedTime[memPage[index]] +
        '</div>')
      )
      else
        $('.memory-div').append '<div class="memory-block">idle block</div>'
    ) for index in [0..MEMORY_BLOCK_MAX - 1]
    $('.memory-block').css('height', (450 / MEMORY_BLOCK_MAX) + 'px')
    global.needUpdateMemoryPages = no
  )
  if global.insLoadTotal is 0 then (
    $('#instruct-total').text = '0'
    $('#page-not-found-rate').text '0%'
  ) else (
    $('#instruct-total').text global.insLoadTotal.toString()
    $('#page-not-found-rate').text (global.pageNotFoundTime * 100 / global.insLoadTotal).toString() + '%'
  )

#############################
# 按钮事件
#############################

# push Instruction 按钮触发
pushEventFunc = (ev)->
  if (checkPage insArr[0]) is yes then (
    loadInstruction()
    global.needUpdateMemoryPages = yes
    global.needUpdateInstructionQueue = yes
    return
  )
  # 如果页面不在内存块中
  global.pageNotFoundTime += 1
  global.algorithmUsing getPageByAddress insArr[0]
  global.needUpdateMemoryPages = yes
  global.needUpdateInstructionQueue = yes

# Auto push 实现
autoPushEventFunc = (ev) ->
  if global.autoplayIntervalId is -1 then (
    global.autoplayIntervalId = setInterval pushEventFunc, 500
    $('#btn-auto-push-next-ins').text 'Pause'
    $('#btn-auto-push-next-ins').addClass 'mui-btn-danger'
  ) else (
    clearInterval global.autoplayIntervalId
    global.autoplayIntervalId = -1
    $('#btn-auto-push-next-ins').text 'Auto push'
    $('#btn-auto-push-next-ins').removeClass 'mui-btn-danger'
  )

FIFOBtnEventFunc = (ev)->
  $('#btn-change-alg-FIFO').addClass('mui-btn-primary')
  $('#btn-change-alg-LRU').removeClass('mui-btn-primary').addClass('mui-btn-defaut')
  $('#btn-change-alg-LFU').removeClass('mui-btn-primary').addClass('mui-btn-defaut')
  global.algorithmUsing = FIFO
  console.log 'Algorithm changed to FIFO'

LRUBtnEventFunc = (ev)->
  $('#btn-change-alg-FIFO').removeClass('mui-btn-primary').addClass('mui-btn-defaut')
  $('#btn-change-alg-LRU').addClass('mui-btn-primary')
  $('#btn-change-alg-LFU').removeClass('mui-btn-primary').addClass('mui-btn-defaut')
  global.algorithmUsing = LRU
  console.log 'Algorithm changed to LRU'

LFUBtnEventFunc = (ev)->
  $('#btn-change-alg-FIFO').removeClass('mui-btn-primary').addClass('mui-btn-defaut')
  $('#btn-change-alg-LRU').removeClass('mui-btn-primary').addClass('mui-btn-defaut')
  $('#btn-change-alg-LFU').addClass('mui-btn-primary')
  global.algorithmUsing = LFU
  console.log 'Algorithm changed to LFU'

###############################
# 算法
###############################

FIFO = (pageInsert)->
  loadInstruction()
  global.popPage = memPage.shift()
  algCount.blockLastVisited.shift()
  memPage.push pageInsert
  algCount.blockLastVisited.push 0
  algCount.pageVisitedTime[pageInsert] += 1
  global.needUpdateMemoryPages = yes

LRU = (pageInsert)->
  loadInstruction()
  popIndex = -1
  longestLastVisit = 0
  (
    (
      longestLastVisit = algCount.blockLastVisited[index]
      popIndex = index
    ) if algCount.blockLastVisited[index] >= longestLastVisit
  ) for index in [0..MEMORY_BLOCK_MAX - 1]
  console.log popIndex
  memPage[popIndex] = pageInsert
  algCount.blockLastVisited[popIndex] = 0
  algCount.pageVisitedTime[pageInsert] += 1
  global.needUpdateMemoryPages = yes

LFU = (pageInsert)->
  loadInstruction()
  popIndex = -1
  leastUsedTime = 0x7fff

  (
    if memPage[index] is null then (
      popIndex = index
      memPage[popIndex] = pageInsert
      algCount.blockLastVisited[popIndex] = 0
      algCount.pageVisitedTime[pageInsert] += 1
      global.needUpdateMemoryPages = yes
      return
    )
  ) for index in [0..MEMORY_BLOCK_MAX - 1]

  (
    (
      leastUsedTime = algCount.pageVisitedTime[index]
      popIndex = index
    ) if algCount.pageVisitedTime[memPage[index]] <= leastUsedTime
  ) for index in [0..MEMORY_BLOCK_MAX - 1]

  console.log popIndex
  memPage[popIndex] = pageInsert
  algCount.blockLastVisited[popIndex] = 0
  algCount.pageVisitedTime[pageInsert] += 1
  global.needUpdateMemoryPages = yes

###############################
# 主函数
###############################
main = ->
  console.log 'Program starts!'
  init()
  initHTML()
  setInterval update, 50
  console.log 'Initialize done!'
  global.algorithmUsing = FIFO
  $('#btn-push-next-ins').click pushEventFunc
  $('#btn-auto-push-next-ins').click autoPushEventFunc
  $('#btn-change-alg-FIFO').click FIFOBtnEventFunc
  $('#btn-change-alg-LRU').click LRUBtnEventFunc
  $('#btn-change-alg-LFU').click LFUBtnEventFunc
  return true

main()
