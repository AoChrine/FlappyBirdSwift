//
//  GameScene.swift
//  FlappyBirdSwift
//
//  Created by Alexander Ou on 9/10/14.
//  Copyright (c) 2014 Alexander Ou. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let verticalObsGap = 160.0
    
    var bird: SKSpriteNode!
    var skyColor: SKColor!
    var sharkTextureUp:SKTexture!
    var hookTextureDown:SKTexture!
    var moveObsAndRemove:SKAction!
    var moving:SKNode!
    var obs:SKNode!
    var canRestart=Bool()
    var scoreLabelNode:SKLabelNode!
    var score=NSInteger()
    
    let birdCategory: UInt32=1 << 0
    let worldCategory: UInt32=1 << 1
    let obsCategory: UInt32=1 << 2
    let scoreCategory: UInt32=1 << 3
    
    
    override func didMoveToView(view: SKView) {
        
        canRestart=false
        
        /* Setup your scene here */
        
        skyColor = SKColor(red: 153.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving=SKNode()
        self.addChild(moving)
        obs=SKNode()
        moving.addChild(obs)
        
        
        // Physics
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0)
        self.physicsWorld.contactDelegate=self
        
        // Make the bird
        let birdTexture1 = SKTexture(imageNamed:"fish1")
        birdTexture1.filteringMode = .Nearest
        let birdTexture2 = SKTexture(imageNamed: "fish2")
        birdTexture2.filteringMode = .Nearest
        
        let anim = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        let flap = SKAction.repeatActionForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
        bird.runAction(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.dynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask=birdCategory
        bird.physicsBody?.collisionBitMask=worldCategory | obsCategory
        bird.physicsBody?.contactTestBitMask=worldCategory | obsCategory
        
        self.addChild(bird)
        
        
        // Ground
        
        let groundTexture = SKTexture(imageNamed:"underwatergroundOPT")
        groundTexture.filteringMode = .Nearest
        
        let moveGroundSprite=SKAction.moveByX(-groundTexture.size().width * 2.0, y: 0, duration: NSTimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite=SKAction.moveByX(groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever=SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))

        for var i:CGFloat = 0; i<2.0+self.frame.size.width / (groundTexture.size().width * 2.0); i++ {
            let sprite=SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position=CGPointMake(i*sprite.size.width, sprite.size.height/2.0)
            sprite.runAction(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        //create the ground
        let ground = SKNode()
        ground.position = CGPointMake(0, groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height * 2.0))
        ground.physicsBody?.dynamic=false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        //init label and create label to hold score
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed: "scoreboard")
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), 3 * self.frame.size.height/4)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        

        // skyline
        let skyTexture=SKTexture(imageNamed: "underwaterlandOPT")
        skyTexture.filteringMode = .Nearest
        
        let moveSkySprite=SKAction.moveByX(-skyTexture.size().width*2.0, y: 0, duration: NSTimeInterval(0.2*skyTexture.size().width*2.0))
        let resetSkySprite=SKAction.moveByX(skyTexture.size().width*2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever=SKAction.repeatActionForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for var i:CGFloat = 0; i<2.0+self.frame.size.width / (skyTexture.size().width * 2.0); i++ {
            let sprite=SKSpriteNode(texture: skyTexture)
            /* how big pic is */ sprite.setScale(1.0)
            sprite.zPosition = -20
            sprite.position=CGPointMake(i*sprite.size.width, sprite.size.height/2.0+groundTexture.size().height*2.0)
            sprite.runAction(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        //create obs texture
        sharkTextureUp = SKTexture(imageNamed: "sharkUP")
        sharkTextureUp.filteringMode = .Nearest
        hookTextureDown=SKTexture(imageNamed: "hookDOWN")
        hookTextureDown.filteringMode = .Nearest
        
        //obs movement action
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * sharkTextureUp.size().width)
        let moveObs=SKAction.moveByX(-distanceToMove, y: 0.0, duration: NSTimeInterval(0.01 * distanceToMove))
        let removeObs=SKAction.removeFromParent()
        moveObsAndRemove = SKAction.sequence([moveObs, removeObs])
        
        //spawn obs
        let spawn = SKAction.runBlock({() in self.spawnObs()})
        let delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
    }
    
        
        func spawnObs(){
            let obsPair = SKNode()
            
            obsPair.position = CGPointMake(self.frame.size.width+sharkTextureUp.size().width*2, 0)
            obsPair.zPosition = -10
            
            let height = UInt32(UInt(self.frame.size.height / 4) )
            let y = arc4random() % height + height
            
            let obsDown = SKSpriteNode(texture: hookTextureDown)
            obsDown.setScale(2.0)
            obsDown.position = CGPointMake(0.0, CGFloat(Double(y)) + obsDown.size.height + CGFloat(verticalObsGap))
            
            obsDown.physicsBody = SKPhysicsBody(rectangleOfSize: obsDown.size)
            obsDown.physicsBody?.dynamic=false
            obsDown.physicsBody?.categoryBitMask=obsCategory
            obsDown.physicsBody?.contactTestBitMask=birdCategory
            obsPair.addChild(obsDown)
            
            let obsUp = SKSpriteNode(texture: sharkTextureUp)
            obsUp.setScale(2.0)
            obsUp.position = CGPointMake(0.0, CGFloat(Double(y)))
            
            obsUp.physicsBody = SKPhysicsBody(rectangleOfSize: obsUp.size)
            obsUp.physicsBody?.dynamic=false
            obsUp.physicsBody?.categoryBitMask=obsCategory
            obsUp.physicsBody?.contactTestBitMask=birdCategory
            obsPair.addChild(obsUp)
            
            let contactNode = SKNode()
            contactNode.position = CGPointMake(obsDown.size.width + bird.size.width/2, CGRectGetMidY(self.frame))
            contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(obsUp.size.width, self.frame.size.height))
            contactNode.physicsBody?.dynamic=false
            contactNode.physicsBody?.categoryBitMask=scoreCategory
            contactNode.physicsBody?.contactTestBitMask=birdCategory
            obsPair.addChild(contactNode)
            
            obsPair.runAction(moveObsAndRemove)
            obs.addChild(obsPair)
        }
    
    func resetScene(){
        // move bird to original position and reset velocity
        bird.position = CGPointMake(self.frame.size.width/2.5, CGRectGetMidY(self.frame))
        bird.physicsBody?.velocity = CGVectorMake(0, 0)
        bird.physicsBody?.collisionBitMask = worldCategory | obsCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // remove all existing pipes
        obs.removeAllChildren()
        
        // reset _canRestart
        canRestart = false
        
        // reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // restart anim
        moving.speed = 0.8
    }
        
        
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        if moving.speed > 0 {
        for touch: AnyObject in touches {
            _ = touch.locationInNode(self)
            bird.physicsBody?.velocity = CGVectorMake(0.0, 0.0)
            bird.physicsBody?.applyImpulse(CGVectorMake(0,30))
            }
        }else if canRestart{
            self.resetScene()
        }
    }
    
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if(value > max) {
            return max
        }else if( value < min) {
            return min
        }else{
            return value
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody!.velocity.dy * (bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory{
                //bird has contact with score entity
                score++
                scoreLabelNode.text = String(score)
                
                // add visual feedback for score increment
                scoreLabelNode.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: NSTimeInterval(0.1)), SKAction.scaleTo(1.0, duration: NSTimeInterval(0.1))]))
            }else{
                moving.speed = 0
                
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.runAction(SKAction.rotateByAngle(CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration: 1), completion:{self.bird.speed = 0})
                
                // flash background if contact is detected
                self.removeActionForKey("flash")
                self.runAction(SKAction.sequence([SKAction.repeatAction(SKAction.sequence([SKAction.runBlock({self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)}), SKAction.waitForDuration(NSTimeInterval(0.05)), SKAction.runBlock({self.backgroundColor = self.skyColor}), SKAction.waitForDuration(NSTimeInterval(0.05))]), count:4), SKAction.runBlock({self.canRestart = true})]), withKey: "flash")
            }
            }
        }
    }

