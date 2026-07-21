using UnityEngine;

public class HealthbarScript : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created

    Material _HealthbarMaterial;

    void Start()
    {
        _HealthbarMaterial = GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        //print("Crack Start = " + _HealthbarMaterial.GetFloat("_CrackStart"));

        if (Input.GetKeyDown(KeyCode.Space))
        {
            _HealthbarMaterial.SetFloat("_CrackStart", Time.time);
            _HealthbarMaterial.SetFloat("_PreviousHealth", _HealthbarMaterial.GetFloat("_Health"));
            _HealthbarMaterial.SetFloat("_Health", (_HealthbarMaterial.GetFloat("_Health") - Random.Range(0.1f, 0.2f)));
            _HealthbarMaterial.SetFloat("_LerpedHealth", _HealthbarMaterial.GetFloat("_PreviousHealth"));
            if (_HealthbarMaterial.GetFloat("_Health") <= 0)
            {
                _HealthbarMaterial.SetFloat("_Health", 1);
                _HealthbarMaterial.SetFloat("_PreviousHealth", _HealthbarMaterial.GetFloat("_Health"));
            }

            print("_PreviousHealth = " + _HealthbarMaterial.GetFloat("_PreviousHealth"));
            print("_Health = " + _HealthbarMaterial.GetFloat("_Health"));
            //print("Difference : " + abs(lerpedHealth - _Health))
            
        }
        print("_LerpedHealth = " + _HealthbarMaterial.GetFloat("_LerpedHealth"));
    }
}
