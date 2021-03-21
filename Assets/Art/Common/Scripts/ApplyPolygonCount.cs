using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyPolygonCount : MonoBehaviour
{
    [SerializeField]
    private string _uniformName = "_PolygonCount";

    private MeshRenderer _meshRenderer = null;
    private MaterialPropertyBlock _materialPropertyBlock = null;
    private MeshFilter _meshFilter = null;

    // Start is called before the first frame update
    void Start()
    {
        _meshRenderer = GetComponent<MeshRenderer>();
        _materialPropertyBlock = new MaterialPropertyBlock();
        _meshFilter = GetComponent<MeshFilter>();

        int polygonCount = _meshFilter.sharedMesh.triangles.Length / 3;

        // for debug
        // Debug.Log(polygonCount);

        _meshRenderer.GetPropertyBlock(_materialPropertyBlock);
        _materialPropertyBlock.SetInt(_uniformName, polygonCount);
        _meshRenderer.SetPropertyBlock(_materialPropertyBlock);
    }
}
