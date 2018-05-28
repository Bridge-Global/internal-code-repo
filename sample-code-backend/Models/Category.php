<?php
/**
 * Category Model
 *
 * @category Category
 * @package  Model
 */

namespace App;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use DB;

class Category extends Model
{

    use SoftDeletes;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'category';

    /**
     * The attributes that should be mutated to dates.
     *
     * @var array
     */
    protected $dates = ['deleted_at'];

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'category_name', 'icon'
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'deleted_at', 'created_at', 'updated_at'
    ];

    /**
     * Get all categories details.
     *
     * @return Array
     */
    public function getAllCategoryDetails() 
    {
        $products = $this->select('category_name', 'category.slug', 'icon', 'category.id as id')
            ->join('products', 'products.category_id', '=', 'category.id')
            ->where('products.active', 1)
            ->where('products.visibility', 1);
                    
        $result = $products->groupBy('products.category_id')->get();
        return $result;
    }

    /**
     * Get count of categories by location.
     *
     * @param Int    $id     category id.
     * @param String $maxLat maxLat.
     * @param String $minLat minLat.
     * @param String $maxLon maxLon.
     * @param String $minLon minLon.
     *
     * @return Array
     */
    public function getAllCategoryCount($id,$maxLat,$minLat,$maxLon,$minLon) 
    {
        
        $products = DB::table('products')->select(DB::raw("count(products.id) as pcount"))
            ->join('product_images AS pi', 'products.id', '=', 'pi.product_id')      
            ->join('users AS user', 'products.user_id', '=', 'user.id')
            
        ->join('category AS cat', 'products.category_id', '=', 'cat.id')   
            
           
            ->where('products.active', 1)  
            ->where('pi.primary_image', 1)
            ->where('products.visibility', 1)
        ->where('user.active', 1)
        ->where('user.confirmed', 1);
            
        if (isset($maxLat) && !empty($maxLat) && isset($maxLon) && !empty($maxLon)) {
                
                
            $result=$products->where(
                function ($query) use ($minLat, $maxLat,$minLon, $maxLon) {
                    $query->WhereBetween('products.location_latitude', [$minLat, $maxLat ])
                        ->whereBetween('products.location_longitude', [$minLon, $maxLon ]);    
                }
            ); 
                
        } 
        $res = $products->where('cat.id', '=', $id)->get();     
        
                
        return  $res;
    }

    /**
     * Get all categories name by search keyword.
     *
     * @param Int    $id      user id.
     * @param String $keyword keyword.
     * @param String $slug    slug.
     *
     * @return Array
     */
    public function getCategoriesByKeyword($id,$keyword,$slug)
    {    

        $query = DB::table('category')
            ->select('id', 'category_name AS name', 'slug')
            ->where('category_name', 'LIKE', '%'.$keyword.'%');
        if (isset($slug) && !empty($slug)) {
            $query->where('slug', $slug);
        }
        $categories_items = $query;
        
        $products_items = DB::table('products')
                    ->select('products.id', 'products.name', 'products.slug')
                    ->leftJoin('product_images AS pi', 'products.id', '=', 'pi.product_id')
                    ->leftJoin('users AS user', 'products.user_id', '=', 'user.id')
                    ->where('products.active', 1)
                    ->where('products.visibility', 1)
                    ->where('pi.primary_image', 1)
                    ->where('user_id', '!=', $id)
                    ->where('user.active', 1)
                    ->where('user.confirmed', 1)
                    ->where('products.name', 'LIKE', '%'.$keyword.'%')
                    ->orWhere('products.additional_info', 'LIKE', '%'.$keyword.'%')
                    ->orWhere('products.location_address', 'LIKE', '%'.$keyword.'%')
                    ->union($categories_items)
                    ->groupby('products.name')
                    ->offset(0)
                    ->limit(15)
                    ->get();
        return $products_items;

    } 

    /**
     * Get all categories.
     *
     * @param String $search_data search data.
     *
     * @return Array
     */
    public function getCategories($search_data)
    {    
         $categories = $this->select('category.*');
            $result=$categories->where(
                function ($query) use ($search_data) {
                    $query->where('category.category_name', 'LIKE', '%'.$search_data.'%')
                        ->orWhere('category.slug', 'LIKE', '%'.$search_data.'%');
                }
            )
        ->orderBy('category.category_name', 'ASC')
            ->paginate(10000);
            
            return $result;
    }

}
