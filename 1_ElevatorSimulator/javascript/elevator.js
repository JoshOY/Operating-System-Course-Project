/* Changeable arguments */

var ELEVATOR_TOTAL = 5;
var FLOOR_TOTAL = 20;

var floorHeight = 79;
var elevatorWidth = 128;
var elevatorOpenMarginWidth = 0;
var elevatorOpenWidth = 60;
var holdTime = 2000; // 2000 means 2s

/* Other arguments */

var ELEVATOR_WAITING = 'WAITING';
var ELEVATOR_MOVING_UP = 'MOVING_UP';
var ELEVATOR_MOVING_DOWN = 'MOVING_DOWN';
var ELEVATOR_DOOR_OPEN = 'DOOR_OPENING';  // The door is open but has its schedule.

var elevatorFloor = [];
var doorIsOpen = [];
var elevatorSchedule = [];
var elevatorScheduleDirection = [];
var elevatorStatus = [];
var taskIntervalId = [];

var buttonOutSideUpStatus = [];
var buttonOutSideDownStatus = [];

var UP = true;
var DOWN = false;

var init = function() {
    for (var i = 0; i < ELEVATOR_TOTAL; ++i) {
        elevatorFloor.push(1);
        doorIsOpen.push([]);
        elevatorSchedule.push([]);
        elevatorScheduleDirection.push([]);
        elevatorStatus.push(ELEVATOR_WAITING);
        buttonOutSideUpStatus.push(false);
        buttonOutSideDownStatus.push(false);
        taskIntervalId.push(-1);

        var appendStr = '<div id="elevator-' + i + '" class="elevator-div">';
        var appendFloorStr = "";
        for (var j = 0; j < FLOOR_TOTAL; ++j) {
            appendFloorStr += '<span class="floor" style="height: '
            + floorHeight + "px\">";

            var elevatorDisplay = "<span class=\"elevator-status-display\"" + ' id="light_' + i + '_' + (FLOOR_TOTAL - j)
                + '">' + (FLOOR_TOTAL - j).toString() + "</span>";
            var doorDisplayLeft = "<span class=\"door-left\" id=\"door_l_" + i + '_' + (FLOOR_TOTAL - j) + "\"></span>";
            var doorDisplayRight = "<span class=\"door-right\" id=\"door_r_" + i + '_' + (FLOOR_TOTAL - j) + "\"></span>";

            appendFloorStr += elevatorDisplay + doorDisplayLeft + doorDisplayRight + "</span>";
            doorIsOpen[i].push(false);
        }
        appendStr += appendFloorStr;
        appendStr += "</div>";
        $(".elevator-container").append(appendStr);

    }
};

var initPanel = function(){
    var divPanel = $('.elevator-call-panel');
    for (var i = 0; i < FLOOR_TOTAL; i++) {
        if (i !== 0) divPanel.append('<button class="mui-btn mui-btn-default mui-btn-raised" id="btn-outside-up-' + (FLOOR_TOTAL - i).toString() + '" onclick="floorCallBtnPress('
        + (FLOOR_TOTAL - i).toString() + ',' + UP.toString() + ')">F' + (FLOOR_TOTAL - i).toString() + '↑</button>');
        if (i !== FLOOR_TOTAL - 1)divPanel.append('<button class="mui-btn mui-btn-default mui-btn-raised" id="btn-outside-down-' + (FLOOR_TOTAL - i).toString() + '" onclick="floorCallBtnPress('
        + (FLOOR_TOTAL - i).toString() + ',' + DOWN.toString() + ')">F' + (FLOOR_TOTAL - i).toString() + '↓</button>');
        divPanel.append('<br />');
    }
};

// animation functions

var animationDoorLeftOpen = function(elevatorIndex, floorIndex){
    var door = $("#door_l_" + elevatorIndex + '_' + floorIndex);
    console.log("Animation activated!");
    door.animate({
        'margin-left': elevatorOpenMarginWidth.toString() + 'px',
        'width': elevatorOpenWidth.toString() + 'px'
    }, holdTime);
};

var animationDoorRightOpen = function(elevatorIndex, floorIndex){
    var door = $("#door_r_" + elevatorIndex + '_' + floorIndex);
    console.log("Animation activated!");
    door.animate({
        'margin-right': elevatorOpenMarginWidth.toString() + 'px',
        'width': elevatorOpenWidth.toString() + 'px'
    }, holdTime);
};

var animationDoorLeftClose = function(elevatorIndex, floorIndex){
    var door = $("#door_l_" + elevatorIndex + '_' + floorIndex);
    console.log("Animation activated!");
    door.animate({
        'margin-left': (elevatorOpenWidth).toString() + 'px',
        'width': (elevatorOpenMarginWidth).toString() + 'px'
    }, holdTime);
};

var animationDoorRightClose = function(elevatorIndex, floorIndex){
    var door = $("#door_r_" + elevatorIndex + '_' + floorIndex);
    console.log("Animation activated!");
    door.animate({
        'margin-right': elevatorOpenWidth.toString() + 'px',
        'width': elevatorOpenMarginWidth.toString() + 'px'
    }, holdTime);
};

var doorOpen = function(i, j) {
    animationDoorLeftOpen(i, j);
    animationDoorRightOpen(i, j);
    doorIsOpen[i][j] = true;
};

var doorClose = function(i, j) {
    animationDoorLeftClose(i, j);
    animationDoorRightClose(i, j);
    doorIsOpen[i][j] = false;
};

var switchLightGreen = function(i, j) {
    // console.log(('#light_' + i + '_' + j));
    var light = $('#light_' + i + '_' + j);
    // console.log(light);
    light.animate({
        backgroundColor: 'rgba(0, 255, 0, 0.5)'
    }, holdTime / 2);
};

var switchLightDark = function(i, j) {
    // console.log(('#light_' + i + '_' + j));
    var light = $('#light_' + i + '_' + j);
    // console.log(light);
    light.animate({
        backgroundColor: 'rgba(0, 255, 0, 0)'
    }, holdTime / 2);
};

var delightOutsideButton = function(floor, direction) {
    if (direction === UP) {
        var btnComponent = $('#btn-outside-up-' + floor.toString());
        buttonOutSideUpStatus[floor] = false;
    }
    else {
        btnComponent = $('#btn-outside-down-' + floor.toString());
        buttonOutSideDownStatus[floor] = false;
    }
    btnComponent.animate({
        'background-color': 'rgba(255, 255, 255, 1)'
    }, 500);
};


// Moving functions

var elevatorMove = function(elevatorIndex) {
    var currentFloor = elevatorFloor[elevatorIndex];

    if (elevatorSchedule[elevatorIndex].length === 0) {
        // console.log("Schedule is empty.");
        clearInterval(taskIntervalId[elevatorIndex]);
        taskIntervalId[elevatorIndex] = -1;
        elevatorStatus[elevatorIndex] = ELEVATOR_WAITING;

        delightOutsideButton(currentFloor, UP);
        delightOutsideButton(currentFloor, DOWN);

        return true;
    }
    var moveToFloor = elevatorSchedule[elevatorIndex][0];

    // console.log('Elevator #' + elevatorIndex + ' will move to floor ' + moveToFloor + '.');

    if (currentFloor === moveToFloor) {
        doorOpen(elevatorIndex, currentFloor);

        elevatorStatus[elevatorIndex] = ELEVATOR_DOOR_OPEN;

        delightOutsideButton(elevatorSchedule[elevatorIndex].shift(),
                             elevatorScheduleDirection[elevatorIndex].shift());

        if (elevatorSchedule[elevatorIndex].length === 0) {
            clearInterval(taskIntervalId[elevatorIndex]);
            taskIntervalId[elevatorIndex] = -1;
            elevatorStatus[elevatorIndex] = ELEVATOR_WAITING;
        }

        return true;
    }

    switch(elevatorStatus[elevatorIndex]) {
        case ELEVATOR_WAITING:
        case ELEVATOR_DOOR_OPEN:
            doorClose(elevatorIndex, currentFloor);
            if (moveToFloor > currentFloor) {
                elevatorStatus[elevatorIndex] = ELEVATOR_MOVING_UP;
            } else {
                elevatorStatus[elevatorIndex] = ELEVATOR_MOVING_DOWN;
            }
            break;
        case ELEVATOR_MOVING_UP:
            switchLightDark(elevatorIndex, currentFloor);
            elevatorFloor[elevatorIndex] += 1;
            switchLightGreen(elevatorIndex, elevatorFloor[elevatorIndex]);
            if (moveToFloor > currentFloor) {
                elevatorStatus[elevatorIndex] = ELEVATOR_MOVING_UP;
            } else {
                elevatorStatus[elevatorIndex] = ELEVATOR_MOVING_DOWN;
            }
            break;
        case ELEVATOR_MOVING_DOWN:
            switchLightDark(elevatorIndex, currentFloor);
            elevatorFloor[elevatorIndex] -= 1;
            switchLightGreen(elevatorIndex, elevatorFloor[elevatorIndex]);
            if (moveToFloor > currentFloor) {
                elevatorStatus[elevatorIndex] = ELEVATOR_MOVING_UP;
            } else {
                elevatorStatus[elevatorIndex] = ELEVATOR_MOVING_DOWN;
            }
            break;
    }

};

var checkSchedule = function(elevatorIndex, floor) {
    if (elevatorSchedule[elevatorIndex].length === 0) {
        return false;
    }
    // We only check the first element on the queue.
    else if (floor === elevatorSchedule[elevatorIndex][0]) {
        elevatorSchedule[elevatorIndex].shift();
        return true;
    }
    return false;
};


var elevatorOutsideAlgorithm = function(floorCall, direction) {
    var elevatorHasNoWaiting = true;
    var nearestElevatorIndex = -1;
    var distanceMin = 99999;

    for (var i = 0; i < ELEVATOR_TOTAL; ++i) {
        if ((elevatorFloor[i] === floorCall) && (elevatorStatus[i] === ELEVATOR_WAITING)) {
            // elevatorSchedule[i] = [floorCall].concat(elevatorSchedule[i]);
            elevatorMove(i);
            return;
        }
    }

    for (i = 0; i < ELEVATOR_TOTAL; ++i) {
        if ((elevatorStatus[i] === ELEVATOR_WAITING) && (Math.abs(elevatorFloor[i] - floorCall) < distanceMin)) {
            distanceMin = Math.abs(elevatorFloor[i] - floorCall);
            nearestElevatorIndex = i;
            elevatorHasNoWaiting = false;
        }
    }

    if (elevatorHasNoWaiting === false) {
        elevatorSchedule[nearestElevatorIndex].push(floorCall);
        elevatorScheduleDirection[nearestElevatorIndex].push(direction);
        elevatorMove(nearestElevatorIndex);
        taskIntervalId[nearestElevatorIndex] = setInterval(function(){
            elevatorMove(nearestElevatorIndex);
        }, holdTime + 50);
        return;
    }
    else {
        distanceMin = 99999;
        nearestElevatorIndex = -1;
    }

    if (elevatorHasNoWaiting && (direction === UP)) {
        console.log('Check up!');

        for (i = 0; i < ELEVATOR_TOTAL; ++i) {
            console.log((elevatorStatus[i] === ELEVATOR_MOVING_UP) && (floorCall < elevatorSchedule[i][0]));
            if ((elevatorStatus[i] === ELEVATOR_MOVING_UP) && (floorCall < elevatorSchedule[i][0])) {
                console.log(distanceMin, + ', ' + (elevatorFloor[i] - floorCall));
                if (distanceMin > (elevatorFloor[i] - floorCall)) {
                    distanceMin = (elevatorFloor[i] - floorCall);
                    nearestElevatorIndex = i;
                    console.log(nearestElevatorIndex);
                }
            }
        }

        console.log(nearestElevatorIndex);
        if (nearestElevatorIndex >= 0) {
            console.log('Priority!');
            elevatorSchedule[nearestElevatorIndex] = [floorCall].concat(elevatorSchedule[nearestElevatorIndex]);
            elevatorScheduleDirection[nearestElevatorIndex] = [UP].concat(elevatorScheduleDirection[nearestElevatorIndex]);
        } else {
            console.log('Not Priority!');
            var nearestElevatorFloor = 99999;
            for (i = 0; i < ELEVATOR_TOTAL; ++i) {
                if (Math.abs(floorCall - elevatorFloor[i]) < nearestElevatorFloor) {
                    nearestElevatorIndex = i;
                    nearestElevatorFloor = elevatorFloor[i];
                }
            }
            elevatorSchedule[nearestElevatorIndex].push(floorCall);
            elevatorScheduleDirection[nearestElevatorIndex].push(UP);
        }
    }

    else if (elevatorHasNoWaiting && (direction === DOWN)) {
        console.log('Check down!');

        for (i = 0; i < ELEVATOR_TOTAL; ++i) {
            if ((elevatorStatus[i] === ELEVATOR_MOVING_DOWN) && (floorCall > elevatorSchedule[i][0])) {
                if (distanceMin > (floorCall - elevatorFloor[i])) {
                    distanceMin = floorCall - elevatorFloor[i];
                    nearestElevatorIndex = i;
                }
            }
        }

        if (nearestElevatorIndex !== -1) {
            console.log('Priority!');
            elevatorSchedule[nearestElevatorIndex] = [floorCall].concat(elevatorSchedule[nearestElevatorIndex]);
            elevatorScheduleDirection[nearestElevatorIndex] = [DOWN].concat(elevatorScheduleDirection[nearestElevatorIndex]);
        } else {
            console.log('Not Priority!');
            nearestElevatorFloor = 99999;
            for (i = 0; i < ELEVATOR_TOTAL; ++i) {
                if (Math.abs(floorCall - elevatorFloor[i]) < nearestElevatorFloor) {
                    nearestElevatorIndex = i;
                    nearestElevatorFloor = elevatorFloor[i];
                }
            }
            elevatorSchedule[nearestElevatorIndex].push(floorCall);
            elevatorScheduleDirection[nearestElevatorIndex].push(DOWN);
        }
    }
};

var runElevator = elevatorOutsideAlgorithm;

// onclick events

var floorCallBtnPress = function(floorCall, direction) {

    if (direction === UP) {
        if (buttonOutSideUpStatus[floorCall]) {
            return false;
        }
        var btnComponent = $('#btn-outside-up-' + floorCall.toString());
        buttonOutSideUpStatus[floorCall] = true;
    }
    else {
        if (buttonOutSideDownStatus[floorCall]) {
            return false;
        }
        btnComponent = $('#btn-outside-down-' + floorCall.toString());
        buttonOutSideDownStatus[floorCall] = true;
    }

    btnComponent.animate({
        'background-color': 'rgba(255, 10, 10, 0.85)'
    }, 500);

    runElevator(floorCall, direction);
};


var innerCallBtnPress = function(index, floorCall) {

    if (elevatorStatus[index] === ELEVATOR_WAITING) {
        if (elevatorFloor[index] === floorCall) {
            return;
        }
        elevatorSchedule[index].push(floorCall);
        if (elevatorFloor[index] < floorCall) {

        }
    }

};


$(document).ready(function() {
    init();
    for (var i = 0; i < ELEVATOR_TOTAL; ++i) {
        doorOpen(i, 1);
        switchLightGreen(i, 1);
    }
    initPanel();
});