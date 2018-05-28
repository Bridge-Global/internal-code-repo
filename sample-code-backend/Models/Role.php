<?php
/**
 * Role Model
 *
 * @package    Media
 * @subpackage Model
 */

namespace App;

use Illuminate\Database\Eloquent\Model;
use Laraveldaily\Quickadmin\Models\Menu;


class Role extends Model
{
    protected $fillable = ['title'];

    public $relation_ids = [];

    /**
     * Retrieve Menu list.
     * 
     * @return String
     */
    public function menus()
    {
        return $this->belongsToMany(Menu::class);
    }

    /**
     * Checking user can access menu.
     * 
     * @param Object $menu menu details.
     *
     * @return Boolean
     */
    public function canAccessMenu($menu)
    {
        if ($menu instanceof Menu) {
            $menu = $menu->id;
        }

        if (! isset($this->relation_ids['menus'])) {
            $this->relation_ids['menus'] = $this->menus()->pluck('id')->flip()->all();
        }

        return isset($this->relation_ids['menus'][$menu]);
    }
}

