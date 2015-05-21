# ȫ�ֱ���
# �����һ����ҵ���ڴ��Ϊ4
MEMORY_BLOCK_MAX = 4
# ÿ��ҳ��ɴ��10��ָ��
PAGE_STORE_MAX = 10
# ��ҵָ������
INSTRUCTS_TOTAL = 320
# ��ַ�ռ�
ADDR_SPACE = INSTRUCTS_TOTAL / PAGE_STORE_MAX

# ָ������
insArr = []
# ��ǰ�ڴ��е�ҳ��
memPage = []

global =
  # ��ǰִ�е�ָ�������
  insM: 0
  # ��һ����ת��ʽ��0 - ˳��ִ�У�1 - ���ַ���֣�2 - ˳��ִ��, 3 - ǰ��ַ���֣�
  jumpType: 0
  # ��ǰʹ�õ��㷨
  algorithmUsing: FIFO
  # ��Ҫ����UI�е�ָ�������ʾ
  needUpdateInstructionQueue: yes
  # ��Ҫ����UI�е��ڴ��
  needUpdateMemoryPages: yes
  # ���ڴ��б�����ȥ��ҳ��
  popPage: null
  # �ڴ��б�ʹ�õ�ҳ�������
  usingPageIndex: -1
  # �Զ�����interval id
  autoplayIntervalId: -1
  # �ܼ�ָ���ȡ
  insLoadTotal: 0
  # ȱҳ����
  pageNotFoundTime: 0
  # ��ǰִ�е�ָ��
  currentIns: -1

algCount =
  # �ڴ���ĳ��ҳ������ϴη����Ѿ���ȥ��ָ�����ڣ�LRU�㷨�ã�
  blockLastVisited: []
  # ����ҳ���ܼƷ��ʴ�����LFU�㷨�ã�
  pageVisitedTime: []


# ��ʼ��ȫ��
init = (memBlockMax = 4, pageStoreMax = 10, insTotal = 320)->
  MEMORY_BLOCK_MAX = memBlockMax
  PAGE_STORE_MAX = pageStoreMax
  INSTRUCTS_TOTAL = insTotal
  ADDR_SPACE = INSTRUCTS_TOTAL / PAGE_STORE_MAX

  # ��ʼ��insArr
  insArr = []

  # ��ʼ��algCount
  algCount.blockLastVisited = []
  algCount.pageVisitedTime = []
  algCount.blockLastVisited.push 9999 for iter in [1..MEMORY_BLOCK_MAX]
  algCount.pageVisitedTime.push 0 for iter in [0..ADDR_SPACE]

  pushInstruction() for iter in [0..9]

  # ��ʼ��memState
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

# ��ʼ��HTML
initHTML = ->
  $('.memory-div').append('<div class="memory-block"></div>') for each in [1..MEMORY_BLOCK_MAX]
  $('.memory-block').css('height', (450 / MEMORY_BLOCK_MAX) + 'px')

# ����ָ��
loadInstruction = ()->
  global.insLoadTotal += 1
  global.currentIns = insArr.shift()
  pushInstruction()

# ҳ�������ڴ�
loadPage = (pageNum, pageOut, exchangeWhich)->
  ret = memPage[exchangeWhich]
  memPage[exchangeWhich] = pageNum
  ret

# ����Ӧָ������ҳ���Ƿ����ڴ���
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

# ��ȡ�ڴ��ַ���ڵ�ҳ������
getPageByAddress = (addr) ->
  return Math.floor (addr / PAGE_STORE_MAX)

# ���º�������setIntervalÿ100����ˢ��һ��
update = ()->
  if global.needUpdateInstructionQueue then (
    $('.instruction-queue').empty()
    $('.instruction-queue').append '<div class="instruction hightlight-blue">' +
      (if global.currentIns >= 0 then global.currentIns.toString() else ' ') + '</div>'
    $('.instruction-queue').append '<div class="instruction">' +
      insArr[index] + '</div>' for index in [0..9]
    global.needUpdateInstructionQueue = no
  );
  if global.needUpdateMemoryPages then (
    $('.memory-div').empty()
    (
      if memPage[index] isnt null then (
        $('.memory-div').append('<div class="memory-block" id="mempage-' + index.toString() + '">' + 'Page #' + memPage[index] +
        '<br />Address: ' + (memPage[index] * PAGE_STORE_MAX) + ' ~ ' + (memPage[index] * PAGE_STORE_MAX + PAGE_STORE_MAX - 1) +
        '<br />Last visit: ' + algCount.blockLastVisited[index] +
        '<br />Page visited: ' + algCount.pageVisitedTime[memPage[index]] +
        '</div>')
      )
      else
        $('.memory-div').append '<div class="memory-block">idle block</div>'
    ) for index in [0..MEMORY_BLOCK_MAX - 1]
    $('.memory-block').css('height', (450 / MEMORY_BLOCK_MAX) + 'px')

    if global.usingPageIndex isnt -1 then (
      $('#mempage-' + global.usingPageIndex).addClass('hightlight-blue')
    )

    global.needUpdateMemoryPages = no
  )
  if global.insLoadTotal is 0 then (
    $('#instruct-total').text '0'
    $('#page-not-found-rate').text '0%'
  ) else (
    $('#instruct-total').text global.insLoadTotal.toString()
    $('#page-not-found-rate').text (global.pageNotFoundTime * 100 / global.insLoadTotal).toString() + '%'
  )

#############################
# ��ť�¼�
#############################

# push Instruction ��ť����
pushEventFunc = (ev)->
  if (checkPage insArr[0]) is yes then (
    global.usingPageIndex = memPage.indexOf getPageByAddress insArr[0]
    loadInstruction()
    global.needUpdateMemoryPages = yes
    global.needUpdateInstructionQueue = yes
    return
  )
  # ���ҳ�治���ڴ����
  global.pageNotFoundTime += 1
  global.algorithmUsing getPageByAddress insArr[0]
  global.needUpdateMemoryPages = yes
  global.needUpdateInstructionQueue = yes

# Auto push ʵ��
autoPushEventFunc = (ev) ->
  if global.autoplayIntervalId is -1 then (
    global.autoplayIntervalId = setInterval pushEventFunc, 100
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

changeSettingsBtnEventFunc = (ev)->
  MEMORY_BLOCK_MAX = memBlockSize = parseInt $('#input-memory-block-num').val() || 4
  PAGE_STORE_MAX = instructionPerPage = parseInt $('#input-instruction-per-page').val() || 10
  INSTRUCTS_TOTAL = instructionTotal = parseInt $('#input-instruction-total').val() || 320

  if global.autoplayIntervalId isnt -1 then (
    clearInterval global.autoplayIntervalId
    global.autoplayIntervalId = -1
    $('#btn-auto-push-next-ins').text 'Auto push'
    $('#btn-auto-push-next-ins').removeClass 'mui-btn-danger'
  )

  global =
    insM: 0
    jumpType: 0
    algorithmUsing: FIFO
    needUpdateInstructionQueue: yes
    needUpdateMemoryPages: yes
    popPage: null
    usingPageIndex: -1
    autoplayIntervalId: -1
    insLoadTotal: 0
    pageNotFoundTime: 0
    currentIns: -1

  algCount =
    # �ڴ���ĳ��ҳ������ϴη����Ѿ���ȥ��ָ�����ڣ�LRU�㷨�ã�
    blockLastVisited: []
    # ����ҳ���ܼƷ��ʴ�����LFU�㷨�ã�
    pageVisitedTime: []

  $('.memory-div').empty()
  $('.instruction-queue').empty()

  init memBlockSize, instructionPerPage, instructionTotal
  initHTML()
  console.log 'Initialize done!'
  return true

  console.log 'Program starts!'
  init()
  initHTML()
  setInterval update, 50
  console.log 'Initialize done!'

###############################
# �㷨
###############################

FIFO = (pageInsert)->
  loadInstruction()
  global.popPage = memPage.shift()
  algCount.blockLastVisited.shift()
  memPage.push pageInsert
  algCount.blockLastVisited.push 0
  algCount.pageVisitedTime[pageInsert] += 1
  global.needUpdateMemoryPages = yes
  global.usingPageIndex = memPage.length - 1

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
  global.usingPageIndex = popIndex


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
      global.usingPageIndex = popIndex
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
  global.usingPageIndex = popIndex

###############################
# ������
###############################
main = ->
  console.log 'Program starts!'
  init()
  initHTML()
  setInterval update, 16
  console.log 'Initialize done!'
  global.algorithmUsing = FIFO
  $('#btn-push-next-ins').click pushEventFunc
  $('#btn-auto-push-next-ins').click autoPushEventFunc
  $('#btn-change-alg-FIFO').click FIFOBtnEventFunc
  $('#btn-change-alg-LRU').click LRUBtnEventFunc
  $('#btn-change-alg-LFU').click LFUBtnEventFunc
  $('#btn-submit-change').click changeSettingsBtnEventFunc
  return true

main()
