Object = require("classic")
Puzzle = Object:extend()

function Puzzle:new(width, height, cellSize)
    self.width = width
    self.height = height
    self.min = 1
    self.max = width * height
    self.cellSize = cellSize
    self.circleRadius = cellSize * 0.4

    -- generate grid, i.e. vertices
    self.grid = {}
    for j = 1, height do
        table.insert(self.grid, {})
        for i = 1, width do
            table.insert(self.grid[j], i + (j-1) * width)
        end
    end

    self.holeCount = math.random(math.ceil(self.max/7))
    self.highest = self.max - self.holeCount

    -- generate graph, i.e. edges
    self.neighborList = {}
    self.graph = {}
    for i = 1, self.max do
        table.insert(self.neighborList, self:getNeighbors(i))
        table.insert(self.graph, self:getNeighbors(i))
    end

    
    self:generateChain()

    self:generatePuzzle()

    self.answers = {} -- cell# = value displayed (position in chain)
    self.reverseAnswers = {} -- value displayed = cell#
    
    for i=1, self.max do
        local ivalue = self.numberPuzzle[i]
        self.answers[i] = ivalue or ''
        -- print('self answers '..i..': '..(self.answers[i] or ''))
        if ivalue ~= nil then
            self.reverseAnswers[ivalue] = i
        end
    end

    self.answerGraph = {}

end

function Puzzle:getCell(x, y)
    -- return self.grid[y][x]
    return x + (y-1) * self.width
end

function Puzzle:getCoord(cell)
    return ((cell - 1) % self.width) + 1, math.ceil(cell/self.width)
end

function Puzzle:getNeighbors(cell)
    local x, y = self:getCoord(cell)
    -- print(cell..": "..x..", "..y)
    local neighborList = {}
    if x > 1 then
        table.insert(neighborList, {x - 1, y})
        if y > 1 then
            table.insert(neighborList, {x - 1, y - 1})
        end
        if y < self.height then
            table.insert(neighborList, {x - 1, y + 1})
        end
    end
    if y > 1 then
        table.insert(neighborList, {x, y - 1})
    end
    if y < self.height then
        table.insert(neighborList, {x, y + 1})
    end
    if x < self.width then
        table.insert(neighborList, {x + 1, y})
        if y > 1 then
            table.insert(neighborList, {x + 1, y - 1})
        end
        if y < self.height then
            table.insert(neighborList, {x + 1, y + 1})
        end
    end
    local neighborCells = {}
    for i, v in ipairs(neighborList) do
        table.insert(neighborCells, self:getCell(v[1], v[2]))
        -- print(cell.."->"..self:getCell(v[1], v[2]))
    end
    return neighborCells
end

function Puzzle:getCircleCenter(cell)
    local x, y = self:getCoord(cell)
    return ((x-0.5) * cellSize), ((y-0.5) * cellSize)
end

function Puzzle:generateChain()
    -- generate chain, i.e. series of edges s.t. all but 2 vertices have 2 edges, the other 2 have 1
    self.chain = {}
    for j = 1, self.max do
        table.insert(self.chain, {})
        -- print(j)
    end
    -- a table that contains all the nodes in the chain
    self.chainStart = math.random(self.max)

    local currentNode = self.chainStart
    self.chain.nodes = {currentNode}
    self.chain.set = {}
    self.chain.set[currentNode] = true
    local counter = 0

    while (counter < self.max * 5) and (#self.chain.nodes < self.highest) do

        -- check to make sure this node has edges
        local possibilities = #self.graph[currentNode]
        local choice = 0
        if possibilities > 0 then
            choice = self.graph[currentNode][math.random(possibilities)]
            table.insert(self.chain[currentNode], choice)
            table.insert(self.chain[choice], currentNode)
            for i, v in ipairs(self.graph[currentNode]) do
                for j, w in ipairs(self.graph[v]) do
                    if w == currentNode then
                        table.remove(self.graph[v], j)
                    end
                end
            end
            self.graph[currentNode] = {}
            -- print('adding edge: '..currentNode..'-'..choice)
            table.insert(self.chain.nodes, choice)
            self.chain.set[choice] = true
            currentNode = choice
        else
            -- print('node '..currentNode..' is trapped!')
            -- choose a random neighbor, but not the one you just came from
            local neighborList = self:getNeighbors(currentNode)
            for i, v in ipairs(neighborList) do
                if v == self.chain[currentNode][1] then
                    table.remove(neighborList, i)
                    break
                end
            end
                    
            choice = neighborList[math.random(#neighborList)]
            -- print('moving to '..choice)

            local tracedNode = self.chain[currentNode][1]
            local tracedEdge = {currentNode, tracedNode}
            -- find edge closest to currentNode
            while tracedEdge[2] ~= choice do
                -- print('tracing back: '..table.concat(tracedEdge, '-'))
                for i, v in ipairs(self.chain[tracedNode]) do
                    if v ~= tracedEdge[1] then
                        tracedEdge = {tracedNode, v}
                        tracedNode = v
                        break
                    end
                end
            end
            -- print('FOUND THE EDGE: '..table.concat(tracedEdge, '-'))

            -- delete tracedEdge
            if self.chain[tracedEdge[1]][1] == tracedEdge[2] then
                table.remove(self.chain[tracedEdge[1]], 1)
            else
                table.remove(self.chain[tracedEdge[1]], 2)
            end
            if self.chain[tracedEdge[2]][1] == tracedEdge[1] then
                table.remove(self.chain[tracedEdge[2]], 1)
            else
                table.remove(self.chain[tracedEdge[2]], 2)
            end

            -- add new edge
            table.insert(self.chain[currentNode], choice)
            table.insert(self.chain[choice], currentNode)
            -- print('adding edge: '..currentNode..'-'..choice)
            currentNode = tracedEdge[1]

            -- give back edges of node whose edge was deleted
            local neighborChoices = self:getNeighbors(currentNode)
            local j, n = 1, #neighborChoices
            for i = 1, n do
                if self.chain.set[neighborChoices[i]] == nil then
                    if (i ~= j) then
                        neighborChoices[j] = neighborChoices[i]
                        neighborChoices[i] = nil
                    end
                    j = j + 1
                else
                    neighborChoices[i] = nil
                end
            end
            self.graph[currentNode] = neighborChoices

        end
        -- self:printChain()
        counter = counter + 1
    end
    -- print('counter: '..counter)
    if (counter >= self.max * 5) then
        love.window.showMessageBox('Notice', 'There was an error generating the puzzle. Please start a new game.', 'info', false)
    end
end

function Puzzle:generatePuzzle()
    -- assign numbers to numberChain, one possible answer
    -- and numberPuzzle, the limited numbers given to the player
    self.numberChain = {}
    self.numberChain[self.chainStart] = 1
    currentNode = self.chain[self.chainStart][1]
    self.numberChain[currentNode] = 2
    local currentEdge = {self.chainStart, currentNode}

    self.numberPuzzle = {}
    self.numberPuzzle[self.chainStart] = 1

    self.puzzleSet = {}
    self.puzzleSet[1] = true

    self.hole = {} -- self.hole[i] is true if i is a hole
    for i = 1, self.max do
        self.hole[i] = true
    end
    self.hole[self.chainStart] = false
    self.hole[currentNode] = false
    
    for i = 3, #self.chain.nodes do
        -- continue down the chain
        for i, v in ipairs(self.chain[currentNode]) do
            if v ~= currentEdge[1] then
                currentEdge = {currentNode, v}
                currentNode = v
                break
            end
        end
        self.hole[currentNode] = false
        self.numberChain[currentNode] = i
        -- 30% chance of showing a number
        if i == #self.chain.nodes or math.random(10) <= 3 then
            self.numberPuzzle[currentNode] = i
            self.puzzleSet[i] = true
            -- print('puzzleset '..i)
        end
    end
end

function Puzzle:drawGraph(graphToDraw)
    love.graphics.setColor(0, 0, 0)
    for i, v in ipairs(graphToDraw) do
        for j, w in ipairs(v) do
            local x1, y1 = self:getCircleCenter(i)
            local x2, y2 = self:getCircleCenter(w)
            love.graphics.line(x1, y1, x2, y2)
        end
    end
end

function Puzzle:drawChain()
    love.graphics.setColor(0, 1, 0)
    local x, y = self:getCircleCenter(self.chainStart)
    love.graphics.circle('line', x, y, 20)

    love.graphics.setColor(0, 0, 0)
    for i, node in ipairs(self.chain) do
        if #node > 0 then
            local x, y = self:getCircleCenter(i)
            love.graphics.circle('line', x, y, 30)
        end
    end
    love.graphics.setColor(0, 0, 1)
    for i, v in ipairs(self.chain) do
        for j, w in ipairs(v) do
            local x1, y1 = self:getCircleCenter(i)
            local x2, y2 = self:getCircleCenter(w)
            love.graphics.line(x1, y1, x2, y2)
        end
    end
end

function Puzzle:printChain()
    for i, node in ipairs(self.chain) do
        print(i..": "..table.concat(node, ", "))
    end
end

function Puzzle:drawPuzzle()
    love.graphics.setFont(numberFont)
    local cellSize = self.cellSize

    for j = 1, self.height do
        for i = 1, self.width do
            local cellNum = self:getCell(i,j)
            local puzzleNumber = self.numberPuzzle[cellNum] or ''
            local answerNumber = self.answers[cellNum] or ''
            if puzzle.numberChain[self:getCell(i,j)] == nil then
                love.graphics.setColor(0.8, 0.8, 0.8, 0.6)
            else
                if puzzleNumber == '' then
                    love.graphics.setColor(0.1, 0.3, 0.9)
                    love.graphics.printf(answerNumber, (i-1) * cellSize, (j-0.75) * cellSize, cellSize, "center", 0)
                else
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.printf(puzzleNumber, (i-1) * cellSize, (j-0.75) * cellSize, cellSize, "center", 0)
                end
                love.graphics.setColor(0, 0, 0)
            end
            love.graphics.circle('line', (i-0.5) * cellSize, (j-0.5) * cellSize, self.circleRadius)
        end
    end
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("max: "..self.highest, 10, 600)
end

function Puzzle:areNeighbors(cell, candidate)
    local neighbors = self:getNeighbors(cell)
    for _, v in ipairs(neighbors) do
        if v == candidate then
            return true
        end
    end
    return false
end

function Puzzle:drawAnswerChain()
    local chainLength = 0
    for i = 1, self.max - 1 do
        local ivalue, nextvalue = self.reverseAnswers[i], self.reverseAnswers[i + 1]
        if ivalue ~= nil and nextvalue ~= nil and self:areNeighbors(ivalue, nextvalue) then
            local x1, y1 = self:getCircleCenter(ivalue)
            local x2, y2 = self:getCircleCenter(nextvalue)
            love.graphics.setColor(0.1, 0.2, 0.7, 0.3)
            love.graphics.line(x1, y1, x2, y2)
            chainLength = chainLength + 1
        end
    end

    return (chainLength == self.highest - 1)

end