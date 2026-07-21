using UnityEngine;

public class HealthbarScript : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created

    Material _HealthbarMaterial;


    void Start()
    {
        _HealthbarMaterial = GetComponent<Renderer>().material;
    }

    void TakeDamage(float damageTaken)
    {
        _HealthbarMaterial.SetFloat("_CrackStart", Time.time);
        _HealthbarMaterial.SetFloat("_PreviousHealth", _HealthbarMaterial.GetFloat("_Health"));
        _HealthbarMaterial.SetFloat("_Health", (_HealthbarMaterial.GetFloat("_Health") - damageTaken));
        _HealthbarMaterial.SetFloat("_LerpedHealth", _HealthbarMaterial.GetFloat("_PreviousHealth"));
        if (_HealthbarMaterial.GetFloat("_Health") <= 0)
        {
            _HealthbarMaterial.SetFloat("_Health", 1);
            _HealthbarMaterial.SetFloat("_PreviousHealth", _HealthbarMaterial.GetFloat("_Health"));
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            TakeDamage(Random.Range(0.1f, 0.2f));
        }
    }
}
