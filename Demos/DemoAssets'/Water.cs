using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Water : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        var sunMatrix = RenderSettings.sun.transform.localToWorldMatrix;
        GetComponent<MeshRenderer>().sharedMaterial.SetMatrix("_MainLightDirection", sunMatrix);
    }
}
