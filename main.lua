-- number train

io.stdout:setvbuf("no")
math.randomseed(os.time())

function love.load()
    require("puzzle")
    ButtonManager = require("simplebutton")

    window = {x = 600, y = 700}

    love.window.setMode(window.x, window.y)
    love.window.setTitle("numeral train")

    love.graphics.setBackgroundColor(1, 1, 1)
    bigFont = love.graphics.newFont(window.y/10)

    loadButtons()

    difficulties = {
        easy = {x = 5, y = 5},
        medium = {x = 7, y = 7},
        hard = {x = 10, y = 10},
        expert = {x = 13, y = 13},
    }

    function resetGame(difficulty)

        xmax, ymax = difficulties[difficulty].x, difficulties[difficulty].y
        cellSize = window.x / difficulties[difficulty].x

        numberFont = love.graphics.newFont(cellSize * 0.4)
        love.graphics.setFont(numberFont)
        
        puzzle = Puzzle(xmax, ymax, cellSize)

        click = {
            x = 0,
            y = 0,
            candidate = 0,
            cell = 0
        }
        mouse = {
            x = 0,
            y = 0
        }

        win = false
        displayWin = true
    end

    resetGame('easy')

    music = love.audio.newSource("ponderpuddle.mp3", "stream")
    music:setLooping(true)
    music:play()
end

function love.update(dt)
    -- controls
    mouse.x, mouse.y = love.mouse.getX(), love.mouse.getY()

    -- if mouse is down, see if it has entered a different AND neighboring cell
    if love.mouse.isDown(1) and not win then
        local candidate = puzzle:getCell(math.ceil(mouse.x/cellSize), math.ceil(mouse.y/cellSize))
        if puzzle.answers[click.cell] ~= '' -- the origin cell is filled
        and puzzle.answers[click.cell] ~= puzzle.highest -- the origin cell is not the highest number
        and isInCell(mouse.x, mouse.y, candidate) -- in the cell
        and puzzle:areNeighbors(click.cell, candidate) -- can only move to neighbors
        and not puzzle.hole[click.cell] -- cannot move from holes
        and not puzzle.hole[candidate] then -- cannot move to holes
            local nextCount = puzzle.answers[click.cell] + 1
            if puzzle.numberPuzzle[candidate] == nil -- the cell we are moving to is not already taken (by the puzzle)
            and puzzle.puzzleSet[nextCount] == nil then -- make sure that number is not already given in the puzzle
                -- if the number appears in a diff cell, delete it from that other one
                local toReplace = puzzle.reverseAnswers[nextCount]
                if toReplace ~= nil and toReplace ~= '' then
                    puzzle.answers[toReplace] = ''
                end
                -- if another number appears in this cell, delete that number
                local toReplace2 = puzzle.answers[candidate]
                if toReplace2 ~= nil and toReplace2 ~= '' then
                    puzzle.reverseAnswers[toReplace2] = nil
                end
                -- update the correct cell and the reverse answer, and make the new cell the old cell for the next action
                puzzle.reverseAnswers[nextCount] = candidate
                puzzle.answers[candidate] = nextCount
                click.cell = candidate
                click.x, click.y = puzzle:getCircleCenter(click.cell)
            elseif puzzle.numberPuzzle[candidate] == puzzle.answers[click.cell] + 1 then
                -- if the number is given and it connects, move to it
                click.cell = candidate
                click.x, click.y = puzzle:getCircleCenter(click.cell)
            end
        end
    end
end

function love.draw()
    
    -- puzzle:drawGraph()
    -- puzzle:drawChain()
    -- love.graphics.print(puzzle.chainStart, 10, 10)
    if love.mouse.isDown(1) then
        if click.cell ~= 0 then
            love.graphics.setColor(0.2, 0.4, 0.8, 0.6)
            local cellX, cellY = puzzle:getCircleCenter(click.cell)
            love.graphics.circle('fill', cellX, cellY, puzzle.circleRadius)
            love.graphics.setColor(0.2, 0.4, 0.8)
            love.graphics.line(mouse.x, mouse.y, click.x, click.y)
        end
    end

    win = puzzle:drawAnswerChain()
    puzzle:drawPuzzle()

    if displayWin and win then
        love.graphics.setFont(bigFont)
        drawWin()
    end

    ButtonManager.draw()

end

function love.mousepressed(x, y, msbutton)
    ButtonManager.mousepressed(x, y, msbutton)
    click.x, click.y = x, y
    click.candidate = puzzle:getCell(math.ceil(x/cellSize), math.ceil(y/cellSize))
    -- print('click candidate = '..click.candidate)
    -- print('puzzleanswers[clickcandidate] = '..(puzzle.answers[click.candidate] or ''))
    if isInCell(x, y, click.candidate) -- if you're clicking in the circle
    and puzzle.answers[click.candidate] ~= '' -- don't count holes
    and puzzle.answers[click.candidate] ~= nil then -- don't trigger outside the cell grid
        click.cell = click.candidate
        click.x, click.y = puzzle:getCircleCenter(click.cell)
    else
        click.cell = 0
    end
end

function love.mousereleased(x, y, msbutton)
    ButtonManager.mousereleased(x, y, msbutton)
end

function distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function isInCell(x, y, cell)
    local centerX, centerY = puzzle:getCircleCenter(cell)
    if distance(centerX, centerY, x, y) <= puzzle.circleRadius then
        return true
    else
        return false
    end
end

function drawWin()
    love.graphics.setColor(0.9, 0.9, 0.95, 0.9)
    love.graphics.rectangle('fill', 0, 0, window.x, window.y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("¡you won!", 0, ymax * cellSize * 0.45, cellSize * xmax, 'center')
    newGameButton.interactable = false
    easyButton.interactable = false
    mediumButton.interactable = false
    hardButton.interactable = false
    expertButton.interactable = false
    cancelButton.interactable = false
    closeButton.enabled = true
end

function loadButtons()
    buttonFont = love.graphics.newFont(20)
    ButtonManager.default.font = buttonFont

    newGameButton = ButtonManager.new("new game", 200, 600, 200, 50)
    newGameButton.padding = {0, 0}
    newGameButton.onClick = function()
        -- show new game buttons
        easyButton.enabled = true
        mediumButton.enabled = true
        hardButton.enabled = true
        expertButton.enabled = true
        cancelButton.enabled = true
    end

    function closeButtons()
        easyButton.enabled = false
        mediumButton.enabled = false
        hardButton.enabled = false
        expertButton.enabled = false
        cancelButton.enabled = false
    end

    easyButton = ButtonManager.new("easy", 10, 650, 100, 50)
    easyButton.onClick = function()
        resetGame('easy')
        closeButtons()
    end
    mediumButton = ButtonManager.new("medium", 130, 650, 100, 50)
    mediumButton.onClick = function()
        resetGame('medium')
        closeButtons()
    end
    hardButton = ButtonManager.new("hard", 250, 650, 100, 50)
    hardButton.onClick = function()
        resetGame('hard')
        closeButtons()
    end
    expertButton = ButtonManager.new("expert", 370, 650, 100, 50)
    expertButton.onClick = function()
        resetGame('expert')
        closeButtons()
    end
    cancelButton = ButtonManager.new("cancel", 490, 650, 100, 50)
    cancelButton.onClick = function()
        closeButtons()
    end

    easyButton.enabled = false
    mediumButton.enabled = false
    hardButton.enabled = false
    expertButton.enabled = false
    cancelButton.enabled = false

    closeButton = ButtonManager.new("close", 250, 400, 100, 50)
    closeButton.onClick = function()
        displayWin = false
        closeButton.enabled = false
        newGameButton.interactable = true
        easyButton.interactable = true
        mediumButton.interactable = true
        hardButton.interactable = true
        expertButton.interactable = true
        cancelButton.interactable = true
    end
    closeButton.enabled = false

    muteButton = ButtonManager.new("mute", 520, 600, 70, 30, true)
    muteButton.onClick = function()
        music:pause()
    end
    muteButton.onToggleOff = function()
        music:play()
    end
end
