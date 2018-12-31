package {
    import flash.system.ApplicationDomain;
    import flash.display.MovieClip;

    public class IconManager {
        private var domain: ApplicationDomain;

        public function IconManager(domain: ApplicationDomain) {
            this.domain = domain;
        }

        public function getIconClass(icon: String): Class {
            if (!domain.hasDefinition("m_" + icon)) {
                return NoIcon;
            }
            return domain.getDefinition("m_" + icon) as Class;
        }

        public function getIconInstance(icon: String): MovieClip {
            var iconClass: Class = this.getIconClass(icon);
            var instance: MovieClip = new iconClass() as MovieClip;
            instance.mouseEnabled = false;
            return instance;
        }
    }
}