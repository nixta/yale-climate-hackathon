// Copyright 2017 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

let initialZ = 8.0

let appCenter = AGSPointMakeWGS84(40.72804090913764, -73.98498999999998)

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: AGSSceneView!
    
    //This is the ARKit ARSCNView, which provides the camera video view and the ARSession
    @IBOutlet var arscnView: ARSCNView!

    @IBOutlet weak var heightLabel: UILabel!
    
    var scene:AGSScene!
    
    //change this to toggle between AR and VR views
    var isVR: Bool = false
    
    let graphicsOverlay = AGSGraphicsOverlay()
    
    var seaGraphic: AGSGraphic = {
        // Convert to Web Mercator so that manipulation ends up being in meters
        let ptWM = AGSGeometryEngine.projectGeometry(appCenter, to: .webMercator())!
        let buffer = AGSGeometryEngine.bufferGeometry(ptWM, byDistance: 5000)!
        let raisedBuffer = AGSGeometryEngine.geometry(bySettingZ: initialZ, in: buffer)
        
        let symbol = AGSSimpleFillSymbol(style: .solid, color: UIColor.blue.withAlphaComponent(0.4), outline: nil)
        return AGSGraphic(geometry: raisedBuffer, symbol: symbol, attributes: nil)
    }()
    
    var floodHeight = initialZ {
        didSet {
            guard let geometry = seaGraphic.geometry else { return }
            
            seaGraphic.geometry = AGSGeometryEngine.geometry(bySettingZ: floodHeight, in: geometry)
            
            heightLabel.text = "\(Double(Int(floodHeight * 10))/10.0)m"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create scene without a basemap.  We'll add content to it.
        scene = AGSScene()

        // Add elevation surface from ArcGIS Online
        let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        surface.name = "baseSurface"
        surface.isEnabled = true
        scene.baseSurface = surface


        // Open the local scene I exported from Open Street Map
        let sceneLayer = AGSArcGISSceneLayer(name: "LowerManhattan")
        sceneLayer.layerID = "EastVillage"
        scene.operationalLayers.add(sceneLayer)
        
        //set the sceneView's UIView.backgroundColor to clear to show the camera view underneath
        sceneView.backgroundColor = .clear
        // Enable AR for scene view.
        sceneView.isARModeEnabled = true;

        // Add a place to hold the flood height polygon - we'll lift the polygon up and down
        // using the slider and the surface model we added earlier will limit it appropriately
        sceneView.graphicsOverlays.add(graphicsOverlay)
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        graphicsOverlay.graphics.add(seaGraphic)
        
        // Scene camera controlled by sensors
        let cameraNYC = AGSCamera(lookAt: appCenter, distance: 200, heading: 180, pitch: -10, roll: 0)
        let fpcController = AGSFirstPersonCameraController(initialPosition: cameraNYC)
        fpcController.translationFactor = 400
        
        //create motion data source for use with ARKit
        let arMotionDataSource = AGSARKitMotionDataSource(arscnView: arscnView)
        fpcController.motionDataSource = arMotionDataSource
        
        //set the camera controller on the scene view to control the camera position
        sceneView.cameraController = fpcController
        
        //start the ARKit motion data source
        arMotionDataSource.start { (error) in
            print("motion data source started with error: " + "\(error?.localizedDescription ?? "no error")")
        }
        
        //set the scene on the scene view
        sceneView.scene = scene
    }
    
    
    @IBAction func floodHeightChanged(_ sender: UISlider) {
        floodHeight = Double(sender.value)
    }
    
    
    @IBAction func basemapChanged(_ sender: UISwitch) {
        sceneView.scene?.basemap = sender.isOn ? AGSBasemap.imageryWithLabels() : nil
    }
}
