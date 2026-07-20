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
        //print("IS DAMAGED = " + _HealthbarMaterial.GetFloat("_IsDamaged"));
        print("Crack Start = " + _HealthbarMaterial.GetFloat("_CrackStart"));

        //if (_HealthbarMaterial.GetFloat("_IsDamaged") > 0)
        //{
        //    print("DAMAGED!!!");
        //    _HealthbarMaterial.SetFloat("_IsDamaged", 0);
        //}

        if (Input.GetKeyDown(KeyCode.Space))
        {
            _HealthbarMaterial.SetFloat("_IsDamaged", 1);
            _HealthbarMaterial.SetFloat("_CrackStart", Time.time);
            _HealthbarMaterial.SetFloat("_Health", (_HealthbarMaterial.GetFloat("_Health") - Random.Range(0.05f, 0.2f)));
            if (_HealthbarMaterial.GetFloat("_Health") <= 0)
            {
                _HealthbarMaterial.SetFloat("_Health", 1);
            }
        }
    }
}
