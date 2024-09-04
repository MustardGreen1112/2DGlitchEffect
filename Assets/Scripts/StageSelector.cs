using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class StageSelector : MonoBehaviour
{

    [SerializeField]
    private GameObject iconPrefab;
    [SerializeField] 
    private Transform _stagePage;
    [SerializeField]
    private GameObject leftBtn,rightBtn;
    [SerializeField]
    private List<Sprite> sprites;

    private float widthPerPic;
    private int ID;

    private void Awake()
    {
        ID = 0;
        //UGUI.
        if (iconPrefab) {
            widthPerPic = iconPrefab.GetComponent<RectTransform>().rect.width;
            foreach(Sprite sprite in sprites)
            {
                Image img = Instantiate(iconPrefab, _stagePage.transform).GetComponent<Image>();
                img.sprite = sprite;
            }
        }
        StartCoroutine(IconFadeIn());
    }
    IEnumerator IconFadeIn()
    {
        float val = 1.0f;
        float speed = 0.72f;
        Shader.SetGlobalFloat("_GlobalController", 1);
        while (val >= 0.005f)
        {
            val -= speed * Time.deltaTime;
            Shader.SetGlobalFloat("_GlobalController", val);
            yield return null;
        }
    }

    //For UGUI button.
    public void SwitchStage(bool left)
    {
        //left
        if (left)
        {
            if(ID != 0)
            {
                _stagePage.GetComponent<RectTransform>().anchoredPosition += new Vector2(widthPerPic, 0);
                ID--;
                StopCoroutine(IconFadeIn());
                StartCoroutine(IconFadeIn());
            }
        }
        //right.
        else
        {
            if (ID != sprites.Count-1)
            {
                _stagePage.GetComponent<RectTransform>().anchoredPosition -= new Vector2(widthPerPic, 0);
                ID++;
                StopCoroutine(IconFadeIn());
                StartCoroutine(IconFadeIn());
            }
        }
    }
}
